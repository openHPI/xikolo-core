# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin: Bans: Create', type: :request do
  subject(:request) { post "/users/#{user['id']}/bans", params:, headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { [] }
  let(:admin) { build(:'account:user') }
  let(:user) { build(:'account:user') }
  let(:params) do
    {
      user_id: user['id'],
    }
  end

  let(:ban_stub) do
    Stub.request(:account, :post, "/users/#{user['id']}/ban").to_return Stub.json(user)
  end

  before do
    stub_user_request permissions:, id: admin['id']

    ban_stub
  end

  context 'with permissions' do
    let(:permissions) { %w[account.user.delete] }

    it 'requests to ban the user and redirects to the user view' do
      request

      expect(ban_stub).to have_been_requested
      expect(flash[:success].first).to eq('The user was banned successfully.')
      expect(response).to redirect_to "http://www.example.com/users/#{user['id']}"
    end

    context 'when the user is not found' do
      let(:ban_stub) do
        Stub.request(:account, :post, "/users/#{user['id']}/ban").to_return Stub.response(status: 404)
      end

      it 'raises an error and redirects to the user view' do
        request

        expect(ban_stub).to have_been_requested
        expect(flash[:error].first).to eq('The user could not be banned.')
        expect(response).to redirect_to "http://www.example.com/users/#{user['id']}"
      end
    end

    context 'when the user cannot be banned' do
      let(:ban_stub) do
        Stub.request(:account, :post, "/users/#{user['id']}/ban").to_return Stub.response(status: 422)
      end

      it 'raises an error and redirects to the user view' do
        request

        expect(ban_stub).to have_been_requested
        expect(flash[:error].first).to eq('The user could not be banned.')
        expect(response).to redirect_to "http://www.example.com/users/#{user['id']}"
      end
    end

    context 'when the user has already been banned' do
      before do
        user.merge!(archived: true)
      end

      it 'requests to ban the user and redirects to the user view' do
        request

        expect(ban_stub).to have_been_requested
        expect(flash[:success].first).to eq('The user was banned successfully.')
        expect(response).to redirect_to "http://www.example.com/users/#{user['id']}"
      end
    end

    context 'when the user tries to ban themselves' do
      subject(:request) { post "/users/#{admin['id']}/bans", params:, headers: }

      let(:ban_stub) do
        Stub.request(:account, :post, "/users/#{admin['id']}/ban").to_return Stub.json(admin)
      end

      it 'raises an error and redirects to the user view' do
        request

        expect(ban_stub).not_to have_been_requested
        expect(flash[:error].first).to eq('You cannot ban yourself.')
        expect(response).to redirect_to "http://www.example.com/users/#{admin['id']}"
      end
    end
  end

  context 'without permissions' do
    it 'shows an error about a lack of permissions and redirects the user' do
      request

      expect(flash[:error].first).to eq('You do not have sufficient permissions for this action.')
      expect(response).to redirect_to root_url
    end
  end
end
