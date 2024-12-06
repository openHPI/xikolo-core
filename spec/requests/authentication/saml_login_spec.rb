# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication: Login with SAML', type: :request do
  describe 'request phase' do
    subject(:saml_login) { get '/auth/test_saml', params: }

    before do
      # To check the actual redirect to the SAML IdP, we need to disable the
      # test mode (which would redirect to our callback route immediately).
      OmniAuth.config.test_mode = false
    end

    context 'without redirect URL' do
      let(:params) { {} }

      it 'passes on to SAML without RelayState' do
        saml_login

        expect(response).to be_redirect
        expect(response.location).to include 'example.com/saml'
        expect(response.location).not_to include 'RelayState'
      end
    end

    context 'with target redirect URL in query params' do
      let(:params) { {redirect_path: '/target'} }

      it 'passes on the redirect URL to SAML via RelayState' do
        saml_login

        expect(response).to be_redirect
        expect(response.location).to include 'example.com/saml'
        expect(response.location).to include '&RelayState=%2Ftarget'
      end
    end
  end

  describe 'callback phase' do
    subject(:saml_callback) { get '/auth/test_saml/callback', params: }

    let(:unsigned_internal_path) { '/target' }
    let(:signed_path) { OmniAuth::Strategies::XikoloSAML.sign(unsigned_internal_path) }

    before do
      OmniAuth.config.add_mock(
        :test_saml,
        uid: '1',
        credentials: {
          token: 'abc',
          secret: 'def',
        }
      )

      Stub.request(:account, :post, '/authorizations')
      Stub.request(:account, :post, '/sessions')
        .to_return Stub.json({user_id: generate(:user_id)})
    end

    context 'without redirect URL' do
      let(:params) { {} }

      it 'redirects to the dashboard (default target)' do
        saml_callback

        expect(response).to redirect_to 'http://www.example.com/dashboard'
      end
    end

    context 'with signed redirect URL in RelayState parameter' do
      let(:params) { {RelayState: signed_path} }

      it 'redirects to the URL identified via RelayState' do
        saml_callback

        expect(response).to redirect_to "http://www.example.com#{unsigned_internal_path}"
      end
    end

    context 'with unsigned relative internal URL in RelayState parameter' do
      let(:params) { {RelayState: unsigned_internal_path} }

      it 'redirects to that internal URL' do
        saml_callback

        expect(response).to redirect_to "http://www.example.com#{unsigned_internal_path}"
      end
    end

    context 'with unsigned absolute internal URL in RelayState parameter' do
      let(:params) { {RelayState: 'http://www.example.com/pages/internal'} }

      it 'redirects to that internal URL' do
        saml_callback

        expect(response).to redirect_to 'http://www.example.com/pages/internal'
      end
    end

    context 'with unsigned absolute external URL (or any unknown content, really) in RelayState parameter' do
      let(:params) { {RelayState: unsigned_external_uri} }
      let(:unsigned_external_uri) { 'https://www.client.com/target' }

      it 'redirects to the dashboard (default target)' do
        saml_callback

        expect(response).to redirect_to 'http://www.example.com/dashboard'
      end
    end
  end
end
