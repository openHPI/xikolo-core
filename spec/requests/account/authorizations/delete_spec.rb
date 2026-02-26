# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Authorizations: Delete', type: :request do
  subject(:request) { get '/dashboard/profile', headers: }

  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_resource) do
    attributes_for(:'account_service/user', id: user.id)
      .merge(consents_url: "http://localhost:3000/account_service/users/#{user[:id]}/consents")
  end
  let(:user) { create(:'account_service/user') }
  let(:features) { {'profile' => true} }
  let(:user_authorizations) { [] }
  let(:authorization) do
    {
      'id' => '81e01000-0000-4444-a000-000000000001',
      'user_id' => user_resource[:id],
      'provider' => 'saml',
    }
  end
  let(:second_authorization) do
    {
      'id' => '81e01000-0000-4444-a000-000000000002',
      'user_id' => user_resource[:id],
      'provider' => 'saml',
    }
  end
  let(:page) { Capybara.string(response.body) }

  before do
    stub_user_request(id: user_resource[:id], features:)
    Stub.request(:account, :get, "/authorizations?user=#{user_resource[:id]}")
      .and_return Stub.json(user_authorizations)
  end

  context 'with only one authorization' do
    let(:user_authorizations) { [authorization] }

    it 'does allow deleting the last connected account' do
      request
      expect(page).to have_text 'Single Sign-On (SAML)'
      expect(page).to have_css('a[data-method="delete"][href="/dashboard/profile/auth/81e01000-0000-4444-a000-000000000001"]')
    end
  end

  context 'with multiple authorizations' do
    let(:user_authorizations) { [authorization, second_authorization] }

    it 'does allow deleting a connected account' do
      request
      expect(page).to have_text 'Single Sign-On (SAML)'
      expect(page).to have_css('a[data-method="delete"][href="/dashboard/profile/auth/81e01000-0000-4444-a000-000000000001"]')
      expect(page).to have_css('a[data-method="delete"][href="/dashboard/profile/auth/81e01000-0000-4444-a000-000000000002"]')
    end
  end
end
