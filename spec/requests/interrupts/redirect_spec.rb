# frozen_string_literal: true

require 'spec_helper'

describe 'Interrupts: Redirect targets / messages', type: :request do
  subject(:request) do
    get page, headers: {
      'Authorization' => "Xikolo-Session session_id=#{stub_session_id}",
    }
  end

  let(:user) { create(:user, id: '2611b7f0-b0dc-43d3-96be-81d810ba2535') }
  let!(:user_resource) do
    stub_user_request(
      id: user.id,
      features: {'profile' => 'true'},
      interrupts:
    )
  end
  let(:interrupts) { %w[mandatory_profile_fields] }

  context 'on another page where interrupts are checked' do
    let(:page) { '/dashboard' }

    it 'redirects to interrupt target' do
      request
      expect(response).to redirect_to '/dashboard/profile'
    end
  end

  context 'on target page of interrupt' do
    let(:page) { '/dashboard/profile' }

    before do
      Stub.request(:account, :get, "/users/#{user_resource[:id]}")
        .to_return Stub.json(user_resource)
      Stub.request(:account, :get, "/users/#{user_resource[:id]}/emails")
        .to_return Stub.json([])
      Stub.request(:account, :get, "/users/#{user_resource[:id]}/consents")
        .to_return Stub.json([])
      Stub.request(:account, :get, "/users/#{user_resource[:id]}/profile")
        .to_return Stub.json({fields: []})
      Stub.request(
        :account, :get, '/authorizations',
        query: {user: user_resource[:id]}
      ).to_return Stub.json([])
    end

    it 'stays on the page' do
      request
      expect(response).to have_http_status :ok
    end
  end

  context 'on target page of a less important interrupt' do
    let(:page) { '/dashboard/profile' }
    let(:interrupts) { %w[new_consents mandatory_profile_fields] }

    it 'redirects to most important interrupt target' do
      request
      expect(response).to redirect_to '/treatments'
    end
  end
end
