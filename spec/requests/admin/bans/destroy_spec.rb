# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin: Bans: Destroy', type: :request do
  subject(:request) { delete "/users/#{banned_user.id}/bans" }

  let(:user) { create(:'account_service/user') }
  let(:admin) { create(:'account_service/user', :gdpr_admin) }
  let(:banned_user) { create(:'account_service/user', :banned) }

  context 'with permissions' do
    before do
      sign_in(user: admin)
    end

    it 'requests to unban the user and redirects to the user view' do
      request

      expect(flash[:success].first).to eq('The user was unbanned successfully.')
      expect(response).to redirect_to "http://www.example.com/users/#{banned_user.id}"
    end

    it 'enqueues a reactivation email job' do
      expect { request }.to have_enqueued_job(NotificationService::SendAccountReactivationEmailJob)
        .with(hash_including(user_id: banned_user.id))
    end
  end

  context 'without permissions' do
    before do
      sign_in(user: user)
    end

    it 'shows an error about a lack of permissions and redirects the user' do
      request

      expect(flash[:error].first).to eq('You do not have sufficient permissions for this action.')
      expect(response).to redirect_to root_url
    end
  end
end
