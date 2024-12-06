# frozen_string_literal: true

require 'spec_helper'

# Since some of the tests in this file use multi-threading, we need to explicitly load some
# application constants, as Rails' auto-loading is not thread-safe.
require_dependency 'content_test'

RSpec.describe ContentTest, type: :model do
  subject(:content_test) do
    described_class.new(identifier: 'a-content-test', course:, groups: %w[group-a group-b])
  end

  let(:course) { create(:course, course_code: 'the-course') }

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'accepts letters, symbols and dashes for identifiers' do
      expect(content_test).to accept_values_for(:identifier, 'red', 'RED', 'variant-2', 'foo-bar')
      expect(content_test).not_to accept_values_for(:identifier, 'foo_bar', 'foo-', '-bar', 'foo--bar')
    end

    it "rejects if there aren't enough groups" do
      expect(content_test).not_to accept_values_for(:groups, %w[group-a])
    end

    it 'rejects invalid group names' do
      expect(content_test).not_to accept_values_for(:groups, %w[a d2f#])
    end

    it 'rejects duplicate groups' do
      expect(content_test).not_to accept_values_for(:groups, %w[with-game with-game])
    end

    it 'rejects two tests with the same identifier for a course' do
      create(:content_test, course:, identifier: 'media')

      expect(ContentTest.new(
        identifier: 'media',
        groups: %w[with-game without-game],
        course:
      )).not_to be_valid
    end

    it 'accepts two tests with different identifiers for a course' do
      create(:content_test, course:, identifier: 'media')

      expect(ContentTest.new(
        identifier: 'game',
        groups: %w[with-game without-game],
        course:
      )).to be_valid
    end

    it 'accepts two tests with same identifiers for different courses' do
      create(:content_test, identifier: 'media')

      expect(ContentTest.new(
        identifier: 'media',
        groups: %w[with-game without-game],
        course:
      )).to be_valid
    end
  end

  describe 'group creation' do
    it 'creates groups with proper names and tags' do
      expect { content_test.save! }.to change(Duplicated::Group, :count).from(0).to(2)
      expect(Duplicated::Group.pluck(:name)).to eq \
        %w[
          course.the-course.content_test.a-content-test.group-a
          course.the-course.content_test.a-content-test.group-b
        ]
      expect(Duplicated::Group.pluck(:tags)).to eq [%w[content_test], %w[content_test]]
    end

    context 'with existing group' do
      let!(:group) do
        Duplicated::Group.create!(name: 'course.the-course.content_test.a-content-test.group-a', tags:)
      end
      let(:tags) { %w[blue] }

      it 'adds the "content_test" tag to the pre-existing list of tags' do
        expect { content_test.save! }.to change(Duplicated::Group, :count).from(1).to(2)
        expect(group.reload.tags).to eq %w[blue content_test]
      end

      context 'already tagged as "content_test"' do
        let(:tags) { %w[content_test] }

        it 'does not add a second tag to the pre-existing list of tags' do
          expect { content_test.save! }.to change(Duplicated::Group, :count).from(1).to(2)
          expect(group.reload.tags).to eq %w[content_test]
        end
      end
    end
  end

  describe 'group assignment' do
    before { content_test.save! }

    let(:group_a) { Duplicated::Group.find_by!(name: 'course.the-course.content_test.a-content-test.group-a') }
    let(:group_b) { Duplicated::Group.find_by!(name: 'course.the-course.content_test.a-content-test.group-b') }

    it 'assigns the first user to the first group' do
      expect(content_test.group_for_user(generate(:user_id))).to eq group_a.id

      expect(Duplicated::Membership.where(group_id: group_a.id).count).to eq 1
    end

    it 'assigns the second user to the second group' do
      expect(content_test.group_for_user(generate(:user_id))).to eq group_a.id
      expect(content_test.group_for_user(generate(:user_id))).to eq group_b.id

      expect(Duplicated::Membership.where(group_id: group_a.id).count).to eq 1
      expect(Duplicated::Membership.where(group_id: group_b.id).count).to eq 1
    end

    it 'assigns the third user to the first group again (round robin)' do
      expect(content_test.group_for_user(generate(:user_id))).to eq group_a.id
      expect(content_test.group_for_user(generate(:user_id))).to eq group_b.id
      expect(content_test.group_for_user(generate(:user_id))).to eq group_a.id

      expect(Duplicated::Membership.where(group_id: group_a.id).count).to eq 2
      expect(Duplicated::Membership.where(group_id: group_b.id).count).to eq 1
    end

    context 'when simultaneous assignments occur', transaction: false do
      subject(:concurrent_assignments) do
        Array.new(concurrency_level) do
          Thread.new(&thread)
        end.each(&:join)
      end

      let(:concurrency_level) { 6 }
      let(:thread) do
        # Load the content test anew to avoid sharing dirty state across threads
        -> { ContentTest.find(content_test.id).group_for_user(generate(:user_id)) }
      end

      it 'distributes users memberships evenly between groups' do
        expect { concurrent_assignments }.not_to raise_error

        expect(Duplicated::Membership.where(group_id: group_a.id).count).to eq 3
        expect(Duplicated::Membership.where(group_id: group_b.id).count).to eq 3
      end

      context 'for the same user' do
        let(:thread) do
          -> { ContentTest.find(content_test.id).group_for_user(user_id) }
        end
        let(:user_id) { generate(:user_id) }

        it 'only assigns the user once' do
          expect do
            concurrent_assignments
          end.to change { Duplicated::Membership.where(user_id:).count }.from(0).to(1)

          membership = Duplicated::Membership.find_by(user_id:)
          expect(membership.group_id).to eq group_a.id
        end
      end
    end

    context 'with existing membership' do
      let(:user_id) { generate(:user_id) }

      before do
        group = Duplicated::Group.find_by!(name: 'course.the-course.content_test.a-content-test.group-b')
        Duplicated::Membership.create!(group:, user_id:)
      end

      it 'does not assign the user to any other group' do
        expect(content_test.group_for_user(user_id)).to eq group_b.id

        expect(Duplicated::Membership.where(user_id:).count).to eq 1
      end
    end
  end
end
