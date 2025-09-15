# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication: Authenticate with SAML', type: :request do
  describe 'request phase' do
    subject(:saml_login) { get '/auth/test_saml' }

    before do
      # To check the actual redirect to the SAML IdP, we need to disable the
      # test mode (which would redirect to our callback route immediately).
      OmniAuth.config.test_mode = false
    end

    it 'passes on to SAML' do
      saml_login
      expect(response).to be_redirect
      expect(response.location).to include 'example.com/saml'
    end

    it 'does not pass any internal state on' do
      saml_login
      expect(response.location).not_to include 'RelayState'
    end

    context 'when the user is logged in' do
      let(:nonce) { SecureRandom.urlsafe_base64 }

      before do
        set_session({id: stub_session_id})
        allow(OmniAuth::NonceStore).to receive(:add).with(stub_session_id).and_return(nonce)
      end

      it 'passes on to SAML' do
        saml_login
        expect(response).to be_redirect
        expect(response.location).to include 'example.com/saml'
      end

      it 'passes the nonce to SAML' do
        saml_login
        expect(response.location).to include "RelayState=#{nonce}"
      end
    end
  end

  describe 'callback phase' do
    subject(:saml_callback) { get '/auth/test_saml/callback' }

    let(:create_session_request) do
      Stub.request(:account, :post, '/sessions').to_return create_session_response
    end
    let(:authorization_id) { SecureRandom.uuid }
    let(:authorization_response) do
      {
        body: {
          id: authorization_id,
          user_id: nil,
          provider: 'test_saml',
          uid: '1',
        }.to_json,
        status: 201,
        headers: {'Content-Type' => 'application/json'},
      }
    end

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
        .to_return authorization_response
      create_session_request
    end

    context 'with an anonymous user' do
      let(:user_id) { nil }

      context 'when autocreate is disabled' do
        # When autocreate is disabled, the account service answers with an error: user_creation_required
        let(:create_session_response) do
          Stub.json({errors: {authorization: 'user_creation_required'}}, status: 422)
        end

        it 'creates a new session' do
          saml_callback
          expect(create_session_request).to have_been_requested
        end

        # In the end, the auth_connect template is rendered to ask the user to either create a new account or connect the
        # authorization to an existing one
        it 'redirects to the new session page' do
          saml_callback
          expect(response).to redirect_to new_session_url
        end
      end

      context 'when autocreate is enabled' do
        let(:create_session_response) { Stub.json(build(:'account:session', user_id: SecureRandom.uuid)) }

        it 'creates a new session' do
          saml_callback
          expect(create_session_request).to have_been_requested
        end

        it 'redirects to the dashboard page of the new user' do
          saml_callback
          expect(response).to redirect_to dashboard_url
        end
      end
    end

    context 'with a formerly logged-in user' do
      subject(:saml_callback) { get '/auth/test_saml/callback', params: {RelayState: nonce} }

      let(:user_id) { SecureRandom.uuid }
      let(:nonce) { SecureRandom.urlsafe_base64 }

      let(:create_session_response) { Stub.json({errors: {authorization: 'user_creation_required'}}, status: 422) }
      let(:show_session_request) do
        Stub.request(:account, :get, "/sessions/#{stub_session_id}",
          query: {embed: 'user,permissions,features', context: 'root'})
          .to_return Stub.json(build(:'account:session', user_id:,
            user: build(:'account:user', id: user_id, anonymous: false)))
      end
      let(:update_authorization_request) do
        Stub.request(
          :account, :put, "/authorizations/#{authorization_id}",
          body: hash_including(user_id:)
        ).to_return Stub.json({id: authorization_id})
      end

      before do
        allow(OmniAuth::NonceStore).to receive(:pop).with(nonce).and_return(stub_session_id)
        show_session_request
        update_authorization_request
      end

      it 'restores the session' do
        saml_callback
        expect(show_session_request).to have_been_requested
      end

      it 'adds the authorization to the user' do
        saml_callback
        expect(update_authorization_request).to have_been_requested
      end

      it 'redirects to the profile page' do
        saml_callback
        expect(response).to redirect_to dashboard_profile_url
      end
    end
  end
end
