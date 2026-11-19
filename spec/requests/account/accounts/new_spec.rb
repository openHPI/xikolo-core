# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Accounts: New', type: :request do
  subject(:page) { result; Capybara.string(response.body) }

  let(:result) { get '/account/new' }

  # Both blocks are toggled client-side as the birthdate is typed, so the
  # server only decides how the form starts out.
  let(:disclaimer) { '[data-guardian-consent-target="disclaimer"]' }
  let(:privacy_agreement) { '[data-guardian-consent-target="privacyAgreement"]' }

  it 'hides the guardian consent and disables its inputs' do
    expect(page).to have_css("#{disclaimer}[hidden]", visible: :all)
    expect(page).to have_field('user_guardian_consent', type: 'checkbox', disabled: true, visible: :all)
  end

  it 'shows the privacy agreement, which underage users give via their guardian instead' do
    expect(page).to have_css("#{privacy_agreement}:not([hidden])")
  end

  context 'when re-rendered for an underage user' do
    let(:result) do
      post '/account', params: {user: {full_name: 'Jane Doe', born_at: 14.years.ago.to_date.iso8601}}
    end

    it 'offers the guardian consent for ticking' do
      expect(page).to have_css("#{disclaimer}:not([hidden])")
      expect(page).to have_field('user_guardian_consent', type: 'checkbox', disabled: false)
    end

    it 'drops the privacy agreement' do
      expect(page).to have_css("#{privacy_agreement}[hidden]", visible: :all)
    end

    it 'explains that the consent has to be accepted' do
      expect(page).to have_text 'must be accepted'
    end
  end

  context 'when re-rendered for a user of age' do
    let(:result) do
      post '/account', params: {user: {full_name: 'Jane Doe', born_at: 40.years.ago.to_date.iso8601}}
    end

    it 'keeps the guardian consent hidden and inert' do
      expect(page).to have_css("#{disclaimer}[hidden]", visible: :all)
      expect(page).to have_field('user_guardian_consent', type: 'checkbox', disabled: true, visible: :all)
    end

    it 'keeps the privacy agreement' do
      expect(page).to have_css("#{privacy_agreement}:not([hidden])")
    end
  end
end
