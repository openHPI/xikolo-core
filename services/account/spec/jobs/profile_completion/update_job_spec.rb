# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProfileCompletion::UpdateJob, type: :job do
  let!(:user) { create(:user, completed_profile: false) }

  describe '#perform' do
    before do
      expect(user).not_to have_feature('account.profile.mandatory_completed')
    end

    it do
      perform_enqueued_jobs do
        described_class.perform_later(user.id)
      end

      expect(user).to have_feature('account.profile.mandatory_completed')
    end
  end
end
