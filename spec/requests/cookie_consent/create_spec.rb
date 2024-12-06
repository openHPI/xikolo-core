# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CookieConsent: Create', type: :request do
  subject(:create_cookie_consent) { post '/cookie_consent', params: }

  let(:params) { {} }

  around {|example| Timecop.freeze(&example) }

  before do
    xi_config <<~YML
      cookie_consents:
        test_consent:
          'en': 'Would you like a cookie?'
          'de': 'Möchten Sie einen Keks?'
    YML
  end

  it 'does not set a consent cookie without provided consent_name' do
    create_cookie_consent

    expect(response).to have_http_status :no_content
    expect(cookies[:cookie_consents]).to be_nil
  end

  context 'when the consent is accepted' do
    let(:params) { {consent_name: 'test_consent', accept: true} }

    it 'sets the consent cookie as accepted' do
      create_cookie_consent

      expect(cookies[:cookie_consents]).to eq('["+test_consent"]')
    end

    it 'sets an expiry date for the cookie' do
      Timecop.travel(2022, 1, 1)

      create_cookie_consent

      expect(response.header['Set-Cookie']).to match(
        %r{cookie_consents=%5B%22%2Btest_consent%22%5D; path=/; expires=Sun, 01 Jan 2023 00:00:00 GMT}
      )
    end
  end

  context 'when the consent is declined' do
    let(:params) { {consent_name: 'test_consent', decline: true} }

    it 'sets the consent cookie as declined' do
      create_cookie_consent

      expect(cookies[:cookie_consents]).to eq('["-test_consent"]')
    end

    it 'sets an expiry date for the cookie' do
      Timecop.travel(2022, 1, 1)

      create_cookie_consent

      expect(response.header['Set-Cookie']).to match(
        %r{cookie_consents=%5B%22-test_consent%22%5D; path=/; expires=Sun, 01 Jan 2023 00:00:00 GMT}
      )
    end
  end
end
