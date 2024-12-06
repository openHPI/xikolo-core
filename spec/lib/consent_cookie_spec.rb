# frozen_string_literal: true

require 'spec_helper'

describe ConsentCookie do
  subject(:consent) { described_class.new(cookie_jar) }

  ##
  # Rails util `ActionDispatch::Cookies::CookieJar` sends the cookies along
  # with the HTTP response. We can assume that Rails, Rack, and browsers do
  # the right thing with the arguments, so we only check for the key-value
  # pairs here. For the correct `expires` header to be set, see the request
  # specs covering the usages of the `ConsentCookie` class.
  let(:cookie_jar) do
    ActionDispatch::Cookies::CookieJar.build(
      ActionDispatch::Request.new(:test),
      {}
    )
  end

  before do
    xi_config <<~YML
      cookie_consents:
        google_analytics:
          en: 'Do you like being tracked?'
    YML
  end

  it 'marks the first consent as the "current" consent' do
    expect(consent.current).to eq(
      name: 'google_analytics',
      texts: {'en' => 'Do you like being tracked?'}
    )
  end

  describe 'accepting a known consent' do
    subject(:accept) { consent.accept('google_analytics') }

    it 'is remembered in a new cookie' do
      expect { accept }.to \
        change { cookie_jar[:cookie_consents] }.to '["+google_analytics"]'
    end

    it 'updates an existing cookie' do
      cookie_jar[:cookie_consents] = '["-google_analytics"]'
      accept
      expect(cookie_jar[:cookie_consents]).to eq '["+google_analytics"]'
    end

    it 'does not ask again afterwards' do
      accept
      expect(consent.current).to be_nil
    end

    it 'is marked as accepted' do
      expect { accept }.to \
        change { consent.accepted?('google_analytics') }.from(false).to(true)
    end
  end

  describe 'declining a known consent' do
    subject(:decline) { consent.decline('google_analytics') }

    it 'is remembered in a new cookie' do
      expect { decline }.to \
        change { cookie_jar[:cookie_consents] }.to '["-google_analytics"]'
    end

    it 'updates an existing cookie' do
      cookie_jar[:cookie_consents] = '["+google_analytics"]'
      decline
      expect(cookie_jar[:cookie_consents]).to eq '["-google_analytics"]'
    end

    it 'does not ask again afterwards' do
      decline
      expect(consent.current).to be_nil
    end

    it 'is not marked as accepted' do
      decline
      expect(consent.accepted?('google_analytics')).to be false
    end
  end

  describe 'unknown consents' do
    it 'does nothing when trying to accept an unknown consent' do
      consent.accept('what_is_this')
      expect(cookie_jar[:cookie_consents]).to be_nil
      expect(consent.accepted?('what_is_this')).to be false
    end

    it 'does nothing when trying to decline an unknown consent' do
      consent.decline('what_is_this')
      expect(cookie_jar[:cookie_consents]).to be_nil
      expect(consent.accepted?('what_is_this')).to be false
    end
  end

  context 'multiple configured consents' do
    before do
      xi_config <<~YML
        cookie_consents:
          1st:
            en: 'Do you like one?'
          2nd:
            en: 'Do you like two?'
          3rd:
            en: 'Do you like three?'
      YML
    end

    it 'marks the first un-decided consent as the "current" consent' do
      consent.accept('1st')
      expect(consent.current).to match hash_including(name: '2nd')

      consent.decline('2nd')
      expect(consent.current).to match hash_including(name: '3rd')
    end

    it 'remembers all of them when accepting multiple consents' do
      consent.accept('1st')
      consent.accept('2nd')

      expect(consent.accepted?('1st')).to be true
      expect(consent.accepted?('2nd')).to be true
      expect(consent.accepted?('3rd')).to be false
    end
  end

  describe 'invalid cookie values' do
    it 'ignores non-JSON strings' do
      cookie_jar[:cookie_consents] = '+google_analytics'
      expect(consent.accepted?('google_analytics')).to be false
    end

    it 'ignores non-arrays in valid JSON' do
      cookie_jar[:cookie_consents] = '{"+google_analytics": true}'
      expect(consent.accepted?('google_analytics')).to be false
    end
  end
end
