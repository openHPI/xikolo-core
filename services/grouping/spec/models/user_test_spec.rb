# frozen_string_literal: true

require 'spec_helper'

describe UserTest, type: :model do
  let(:user_id) { SecureRandom.uuid }
  let(:group) { 1 }
  let(:is_admin) { false }

  before do
    Stub.request(
      :account, :get, "/users/#{user_id}"
    ).to_return Stub.json({
      admin: is_admin,
    })
  end

  describe '(creation)' do
    subject(:user_test) { described_class.create!(user_test_params) }

    let(:user_test_params) do
      {
        name: 'New user test',
        identifier: 'user_test',
        start_date: Time.current,
        end_date: 1.week.from_now,
      }
    end

    it 'adds a flipper removal job' do
      expect { user_test }.to change { FeatureFlipperWorker.jobs.size }.from(0).to(1)
    end

    it 'adds a random assignment rule by default' do
      expect(user_test.assignment_rule).to be_a AssignmentRules::RandomAssignmentRule
    end

    context 'with round robin assignment' do
      let(:user_test_params) { super().merge(round_robin: true) }

      it 'adds a round robin assignment rule' do
        expect(user_test.assignment_rule).to be_a AssignmentRules::RoundRobinAssignmentRule
      end
    end
  end

  describe '(validation)' do
    let!(:user_test) { create(:user_test, identifier: 'user_test') }

    context 'when a global user test exists' do
      it 'does not allow another global user test with the same identifier' do
        expect(
          build(:user_test, identifier: user_test.identifier)
        ).not_to be_valid
      end
    end

    context 'when a course-specific user test exists' do
      let(:course_id) { SecureRandom.uuid }
      let(:other_course_id) { SecureRandom.uuid }
      let(:user_test) { create(:user_test, identifier: 'user_test', course_id: other_course_id) }

      it 'allows a user test with the same identifier for a different course' do
        expect(
          build(:user_test, identifier: user_test.identifier, course_id:)
        ).to be_valid
      end

      it 'does not allow a user test with the same identifier for the same course' do
        expect(
          build(:user_test, identifier: user_test.identifier, course_id: other_course_id)
        ).not_to be_valid
      end

      it 'does not allow a global user test with the same identifier' do
        expect(
          build(:user_test, identifier: user_test.identifier)
        ).not_to be_valid
      end
    end
  end

  describe 'flipper removal' do
    let!(:user_test) { create(:user_test_w_test_groups, identifier: 'user_test', end_date: 2.minutes.ago) }
    let!(:flippers_removal) do
      Array.new(user_test.test_groups.count) do |i|
        Stub.request(
          :account, :get, "/groups/grouping.user_test.#{i}"
        ).to_return Stub.json({
          flippers_url: "/groups/grouping.user_test.#{i}/flippers",
        })
        Stub.request(
          :account, :patch, "/groups/grouping.user_test.#{i}/flippers",
          query: {context: 'root'},
          body: {"nudging.variant_#{i + 1}" => nil}
        )
      end
    end

    it 'removes the flipper after end' do
      user_test
      FeatureFlipperWorker.perform_one
      expect(flippers_removal).to all have_been_requested
      user_test.test_groups.each do |test_group|
        expect(test_group.invalidated_flipper).to be true
      end
    end

    it 'removes the flipper after end only once' do
      user_test
      user_test.update! end_date: user_test.end_date + 2.hours
      FeatureFlipperWorker.perform_one
      Timecop.freeze(user_test.end_date + 3.hours) do
        FeatureFlipperWorker.perform_one
      end
      expect(flippers_removal).to all have_been_requested.once
    end
  end

  describe '#assign' do
    let!(:user_test) { create(:user_test_w_test_groups, identifier: 'user_test') }
    let(:test_group) { user_test.test_groups.find_by(index: 0) }
    let(:group) { test_group.index }

    let!(:membership_tg) do
      Stub.request(
        :account, :post, '/memberships',
        body: {user: user_id, group: 'test_group_name'}
      ).to_return Stub.json({})
    end

    # rubocop:disable RSpec/AnyInstance
    before do
      allow_any_instance_of(AssignmentRules::RandomAssignmentRule).to receive(:assign)
        .with(anything)
        .and_return(group)

      allow_any_instance_of(TestGroup).to receive(:group_name).and_return 'test_group_name'
    end
    # rubocop:enable RSpec/AnyInstance

    it 'assigns the user to a group' do
      expect do
        user_test.assign user_id
      end.to change { test_group.trials.count }.from(0).to(1)
    end

    it 'multiple calls of assign should only create trial once' do
      2.times { user_test.assign user_id }
      expect(Trial.count).to eq 1
    end

    it 'creates adds the user to the test group group' do
      user_test.assign user_id
      expect(membership_tg).to have_been_requested
    end

    context 'when not started yet' do
      let(:user_test) do
        create(:user_test_w_test_groups,
          identifier: 'user_test',
          start_date: 1.day.from_now,
          end_date: 2.days.from_now)
      end

      it 'does not assign the user to a group' do
        expect(user_test.assign(user_id)).not_to be_new
      end
    end

    context 'when expired' do
      let(:user_test) do
        create(:user_test_w_test_groups,
          identifier: 'user_test',
          end_date: 1.day.ago)
      end

      it 'does not assign the user to a group' do
        expect(user_test.assign(user_id)).not_to be_new
      end
    end

    context 'with max_participants' do
      let(:user_test) do
        create(:user_test_w_test_groups,
          identifier: 'user_test',
          max_participants:)
      end

      context 'when max_participants reached' do
        let(:max_participants) { 0 }

        it 'does not assign the user to a group' do
          expect(user_test.assign(user_id)).not_to be_new
        end
      end

      context 'when max_participants not reached' do
        let(:max_participants) { 2 }

        it 'does assign the user to a group' do
          expect(user_test.assign(user_id)).to be_new
        end

        it 'makes the new features available' do
          expect(user_test.assign(user_id).new_features).to eq(
            'nudging.variant_1' => true
          )
        end

        it 'does not end the user test' do
          user_test.assign user_id
          expect(user_test.finished?).to be false
        end
      end

      context 'when trials reach max_participants' do
        let(:max_participants) { 1 }

        it 'does assign the user to a group' do
          expect(user_test.assign(user_id)).to be_new
        end

        it 'makes the new features available' do
          expect(user_test.assign(user_id).new_features).to eq(
            'nudging.variant_1' => true
          )
        end

        it 'ends the user test' do
          user_test.assign user_id
          expect(user_test.finished?).to be true
        end
      end
    end

    context 'with filters' do
      before do
        Stub.request(
          :account, :get, "/users/#{user_id}"
        ).to_return Stub.json({
          profile_url: "/users/#{user_id}/profile",
        })
        Stub.request(
          :account, :get, "/users/#{user_id}/profile"
        ).to_return Stub.json({
          fields: [
            {name: 'gender', values: ['female']},
          ],
        })
      end

      context 'accepting' do
        before { user_test.filters << create(:filter) }

        it 'does assign the user to a group' do
          expect(user_test.assign(user_id)).to be_new
        end

        it 'makes the new features available' do
          expect(user_test.assign(user_id).new_features).to eq(
            'nudging.variant_1' => true
          )
        end
      end

      context 'rejecting' do
        before { user_test.filters << create(:filter, operator: '!=') }

        it 'does not assign the user to a group' do
          expect(user_test.assign(user_id)).not_to be_new
        end
      end
    end

    context 'with excluded groups' do
      # Test with round robin so we can expect the assigned groups
      subject(:assignment) { user_test.assign user_id, autofinish: true, exclude_groups: excluded_groups }

      let(:user_test) { create(:user_test_w_test_groups, :round_robin, identifier: 'user_test') }
      let(:excluded_groups) { %w[0] }

      it 'does assign the user to a group' do
        expect(assignment).to be_new
      end

      it 'skips the specified group' do
        assignment
        expect(user_test.round_robin_counter).to eq 0
      end

      it 'makes the new features available' do
        expect(assignment.new_features).to eq 'nudging.variant_2' => true
      end

      context 'with all groups excluded' do
        let(:excluded_groups) { %w[0 1] }

        it 'does not assign the user to a group' do
          expect(assignment).not_to be_new
        end
      end
    end

    context 'with course_id' do
      let(:course_id) { SecureRandom.uuid }
      let(:user_test) { create(:user_test_w_test_groups, identifier: 'user_test', course_id:) }

      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id:}
        ).to_return Stub.json([
          {role:},
        ])
      end

      context 'as student' do
        let(:role) { 'student' }

        it 'assign user' do
          expect { user_test.assign user_id }.to change(Trial, :count).from(0).to(1)
        end
      end
    end
  end

  describe 'update' do
    let!(:user_test) { create(:user_test, identifier: 'user_test') }

    before do
      FeatureFlipperWorker.drain
    end

    context 'without end date change' do
      it 'does not create a flipper removal job' do
        expect { user_test.update! name: 'New' }.not_to change { FeatureFlipperWorker.jobs.size }
      end
    end

    context 'with end date change' do
      it 'creates a flipper removal job' do
        expect { user_test.update! end_date: user_test.end_date + 2.days }.to \
          change { FeatureFlipperWorker.jobs.size }.from(0).to(1)
      end
    end
  end

  describe '#waiting_count' do
    let!(:user_test) { create(:user_test_w_waiting_metric_and_results_trials_waiting, identifier: 'user_test') }

    it 'returns the correct value' do
      expect(user_test.waiting_count).to be_a Hash
      expect(user_test.waiting_count.values).to contain_exactly(0, 4)
    end
  end

  describe '#mean' do
    let!(:user_test) { create(:user_test_w_waiting_metric_and_results, identifier: 'user_test') }

    it 'returns the correct value' do
      expect(user_test.mean).to be_a Hash
      expect(user_test.mean.values).to contain_exactly(0, 1)
    end
  end
end
