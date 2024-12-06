# frozen_string_literal: true

module Steps
  module Admin
    module LtiProvider
      Given 'I am on the LTI provider admin page' do
        visit '/admin/lti_providers'
      end

      When 'I create a new LTI Provider' do
        click_on 'Create new LTI Provider'
      end

      When 'I fill in the LTI provider details' do
        fill_in 'Name', with: 'LTI provider 1'
        fill_in 'Launch URL', with: 'https://www.example.com/launch'
        fill_in 'OAuth consumer key', with: 'oauth_consumer_key'
        fill_in 'OAuth secret', with: 'oauth_secret'
      end

      When 'I submit the LTI provider form' do
        click_on 'Save'
      end

      When 'I select unprotected' do
        choose 'unprotected'
      end

      When 'I click cancel on the confirmation dialog' do
        click_on 'Reset to \'anonymized\''
      end

      When 'I click confirm on the confirmation dialog' do
        click_on 'Confirm'
      end

      Then 'I see a modal to confirm the privacy option' do
        expect(page).to have_content \
        'If the provider is \'unprotected\', personal data might be passed to third parties'
      end

      Then 'the privacy value should be anonymized again' do
        expect(page).to have_checked_field 'anonymized'
      end

      Then 'the privacy value should be unprotected' do
        expect(page).to have_checked_field 'unprotected'
      end

      Then 'I am on the LTI provider admin page' do
        expect(page).to have_current_path '/admin/lti_providers'
      end

      Then 'the global LTI provider is available' do
        expect(page).to have_content 'LTI provider 1'
        expect(page).to have_content 'https://www.example.com/launch'
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Admin::LtiProvider }
