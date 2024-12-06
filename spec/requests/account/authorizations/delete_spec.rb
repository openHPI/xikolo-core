# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Authorizations: Delete', type: :request do
  subject(:request) { get '/dashboard/profile', headers: }

  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user) { build(:'account:user') }
  let(:features) { {'profile' => true} }
  let(:user_authorizations) { [] }
  let(:authorization) do
    build(
      :'account:authorization',
      id: '81e01000-0000-4444-a000-000000000001',
      user_id: user['id'],
      provider: 'saml'
    )
  end
  let(:second_authorization) do
    build(
      :'account:authorization',
      id: '81e01000-0000-4444-a000-000000000002',
      user_id: user['id'],
      provider: 'saml'
    )
  end
  let(:page) { Capybara.string(response.body) }

  before do
    stub_user_request(id: user['id'], features:)
    Stub.request(:account, :get, "/users/#{user['id']}")
      .and_return Stub.json(user)
    Stub.request(:account, :get, "/users/#{user['id']}/emails")
      .and_return Stub.json([
        build(:'account:email', user_id: user['id'], address: user['email']),
      ])
    Stub.request(:account, :get, "/users/#{user['id']}/profile")
      .and_return Stub.json(build(:'account:profile', user_id: user['id']))
    Stub.request(:account, :get, "/users/#{user['id']}/consents")
      .and_return Stub.json([])
    Stub.request(:account, :get, "/authorizations?user=#{user['id']}")
      .and_return Stub.json(user_authorizations)
    Stub.request(:account, :get, "/authorizations/#{authorization['id']}")
      .and_return Stub.json(authorization)
    Stub.request(:account, :get, "/authorizations/#{second_authorization['id']}")
      .and_return Stub.json(second_authorization)
  end

  context 'with native login disabled' do
    context 'with only one authorization' do
      let(:user_authorizations) { [authorization] }

      it 'does not allow deleting the last connected account' do
        request
        expect(page).to have_text 'Single Sign-On (SAML)'
        expect(page).to have_no_selector('a[data-method="delete"][href="/dashboard/profile/auth/81e01000-0000-4444-a000-000000000001"]')
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

  context 'with native login enabled' do
    let(:features) { super().merge('account.login' => true) }

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
end
