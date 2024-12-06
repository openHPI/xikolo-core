# frozen_string_literal: true

module Steps
  module Global
    module CookieConsents
      Given 'a cookie consent was set up' do
        set_xikolo_config('cookie_consents', test_consent: {
          en: 'Would you like a cookie?',
          de: 'Möchten Sie einen Keks?',
        })
      end

      Then 'I should see the cookie consent banner' do
        expect(page).to have_text 'Would you like a cookie?'
      end

      Then 'I should not see the cookie consent banner' do
        expect(page).not_to have_text 'Would you like a cookie?'
      end

      When(/^I click on the banner "(.*)" button$/) do |text|
        within '.cookie-consent-banner' do
          page.click_on text
        end
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Global::CookieConsents }
