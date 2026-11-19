# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin: Bans: Create', type: :request do
  subject(:request) { post "/users/#{user.id}/bans" }

  let(:admin) { create(:'account_service/user', :gdpr_admin) }
  let(:user) { create(:'account_service/user') }

  context 'with permissions' do
    before do
      sign_in(user: admin)
    end

    it 'requests to ban the user and redirects to the user view' do
      request

      expect(flash[:success].first).to eq('The user was banned successfully.')
      expect(response).to redirect_to "http://www.example.com/users/#{user.id}"
    end

    context 'when the user tries to ban themselves' do
      subject(:request) { post "/users/#{admin.id}/bans" }

      it 'raises an error and redirects to the user view' do
        request

        expect(flash[:error].first).to eq('You cannot ban yourself.')
        expect(response).to redirect_to "http://www.example.com/users/#{admin[:id]}"
      end
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
