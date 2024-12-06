# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Assignment: Create', type: :request do
  subject(:creation) { api.rel(:user_assignments).post(params, user_id:).value! }

  let(:api)             { Restify.new(:test).get.value! }
  let(:user_id)         { '00000001-3100-4444-9999-000000000003' }
  let(:course_id)       { '00000001-3300-4444-9999-000000000001' }
  let(:other_course_id) { '00000001-3300-4444-9999-000000000002' }
  let(:identifier)      { 'foo' }
  let(:params) do
    {
      identifier:,
    }
  end

  let!(:global_experiment_1) { create(:user_test_w_test_groups, identifier: 'foo') }
  let!(:global_experiment_2) { create(:user_test_w_test_groups, identifier: 'bar') }

  let!(:course_experiment_1) { create(:user_test_w_test_groups, identifier: 'course1', course_id:) }

  before do
    # More experiments: One in the same course, one in another
    create(:user_test_w_test_groups, identifier: 'course2', course_id:)
    create(:user_test_w_test_groups, identifier: 'course1', course_id: other_course_id)

    Stub.request(
      :account, :post, '/memberships'
    )

    allow_any_instance_of(TestGroup).to receive(:group_name).and_return 'test_group_name' # rubocop:disable RSpec/AnyInstance
  end

  context 'when no experiment matches' do
    let(:identifier) { 'nonexistent' }

    it 'responds with 200 Ok' do
      expect(creation.response.status).to eq :ok
    end

    it 'does not assign the user to any group' do
      expect { creation }.not_to change(Trial, :count)
    end

    it 'returns an empty hash of feature flipper(s) in the response body' do
      expect(creation.to_h).to eq 'features' => {}
    end
  end

  context 'in the global context' do
    it 'responds with 201 Created' do
      expect(creation.response.status).to eq :created
    end

    it 'assigns the user to the correct global experiment' do
      expect { creation }.to \
        change { global_experiment_1.trials.count }.by(1).and \
          change(Trial, :count).from(0).to(1)
    end

    it 'returns the user\'s new feature flipper(s) in the response body' do
      expect(creation.to_h).to eq \
        'features' => {
          'nudging.variant_1' => true,
        }
    end
  end

  context 'in a course context' do
    let(:params) { super().merge course_id: }
    let(:identifier) { 'course1' }

    it 'assigns the user to the correct course-specific experiment' do
      expect { creation }.to \
        change { course_experiment_1.trials.count }.by(1).and \
          change(Trial, :count).from(0).to(1)
    end

    it 'returns the user\'s new feature flipper(s) in the response body' do
      expect(creation.to_h).to eq \
        'features' => {
          'nudging.variant_1' => true,
        }
    end

    context 'with a global experiment matching' do
      let(:identifier) { 'bar' }

      it 'assigns the user to the matching global experiment' do
        expect { creation }.to \
          change { global_experiment_2.trials.count }.by(1).and \
            change(Trial, :count).from(0).to(1)
      end

      it 'returns the user\'s new feature flipper(s) in the response body' do
        expect(creation.to_h).to eq \
          'features' => {
            'nudging.variant_1' => true,
          }
      end
    end
  end

  describe 'excluded groups' do
    # Test with round robin so we can expect the assigned groups
    let(:identifier) { 'rr' }

    before do
      create(:user_test_w_test_groups, :round_robin, identifier:)
    end

    context 'w/o excluded group' do
      it 'returns the user\'s new feature flipper(s) in the response body' do
        expect(creation.to_h).to eq \
          'features' => {
            'nudging.variant_1' => true,
          }
      end
    end

    context 'w/ excluded group' do
      let(:params) { super().merge exclude_groups: %w[0] }

      it 'returns the user\'s new feature flipper(s) in the response body' do
        expect(creation.to_h).to eq \
          'features' => {
            'nudging.variant_2' => true,
          }
      end
    end

    context 'w/ all groups excluded' do
      let(:params) { super().merge exclude_groups: %w[0 1] }

      it 'returns an empty hash of feature flipper(s) in the response body' do
        expect(creation.to_h).to eq 'features' => {}
      end
    end
  end
end
