# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication: Login with SAML', type: :request do
  # Localization for test provider that is only present in these tests.
  around do |example|
    I18n.backend.store_translations('en', {account: {sessions: {auth_connect: {provider_label: {test_saml: 'Test SAML'}}}}})
    example.run
  ensure
    I18n.backend.reload!
  end

  describe 'request phase' do
    subject(:saml_login) { get '/auth/test_saml' }

    before do
      # To check the actual redirect to the SAML IdP, we need to disable the
      # test mode (which would redirect to our callback route immediately).
      OmniAuth.config.test_mode = false
    end

    it 'passes on to SAML without a RelayState' do
      saml_login

      expect(response).to be_redirect
      expect(response.location).to include 'example.com/saml'
      expect(response.location).not_to include 'RelayState'
    end
  end

  describe 'callback phase' do
    subject(:saml_callback) { get '/auth/test_saml/callback' }

    before do
      OmniAuth.config.add_mock(
        :test_saml,
        uid: '1',
        credentials: {
          token: 'abc',
          secret: 'def',
        }
      )
      set_session({provider: 'test_saml', saml_uid: '1', saml_session_index: SecureRandom.uuid})

      Stub.request(:account, :post, '/authorizations')
      Stub.request(:account, :post, '/sessions')
        .to_return Stub.json({user_id: generate(:user_id)})
    end

    it 'redirects to the dashboard (default target)' do
      saml_callback
      expect(response).to redirect_to 'http://www.example.com/dashboard'
    end
  end
end
