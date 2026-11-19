# frozen_string_literal: true

require 'spec_helper'

describe 'Global: Cookie consents', type: :system do
  before do
    xi_config <<~YML
      cookie_consents:
        test_consent:
          en: 'Would you like a cookie?'
          de: 'Möchten Sie einen Keks?'
    YML
  end

  it 'accepts the consent' do
    visit '/'
    expect(page).to have_text('Would you like a cookie?')

    within '.cookie-consent-banner' do
      click_on 'Accept'
    end

    expect(page).to have_no_css('.cookie-consent-banner')

    visit '/'
    expect(page).to have_current_path('/')
    expect(page).to have_no_text('Would you like a cookie?')
  end

  it 'declines the consent' do
    visit '/'
    expect(page).to have_text('Would you like a cookie?')

    within '.cookie-consent-banner' do
      click_on 'Decline'
    end

    # Wait for the banner to disappear after declining
    expect(page).to have_no_css('.cookie-consent-banner', wait: 5)

    visit '/'
    expect(page).to have_current_path('/')
    expect(page).to have_no_text('Would you like a cookie?')
  end

  it 'closes the consent banner' do
    visit '/'
    expect(page).to have_text('Would you like a cookie?')

    within '.cookie-consent-banner' do
      click_on 'Close'
    end

    visit '/'
    expect(page).to have_text('Would you like a cookie?')
  end
end
