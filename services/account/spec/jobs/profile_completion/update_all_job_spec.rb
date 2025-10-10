# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProfileCompletion::UpdateAllJob, type: :job do
  let!(:users) do
    create_list(:'account_service/user', 10, completed_profile: false)
  end

  describe '#perform' do
    before do
      expect(users).not_to include have_feature('account.profile.mandatory_completed')
    end

    it do
      perform_enqueued_jobs do
        described_class.perform_later
      end

      expect(users).to all have_feature('account.profile.mandatory_completed')
    end
  end
end
