# frozen_string_literal: true

module Steps
  module SamlSso
    Given 'I am Lassie' do
      create_and_assign_user full_name: 'Lassie Fairy', email: 'lassie@company.com'
    end

    Given 'I am casual Lassie' do
      create_and_assign_user full_name: 'Lassie F.', email: 'lassie_f@web.de'
    end

    Given 'I have an authorization' do
      create_authorization info: {email: context.fetch(:user)['email']}
    end

    Given 'there is an account with my work e-mail and SSO connection' do
      old_user = create_user(email: 'lassie@company.com', full_name: 'Lassie Fairy')
      data = Factory.create(:authorization, {user_id: old_user.id, info: {email: 'lassie@company.com'}})
      Server[:account].api.rel(:authorizations).post(data).value!
    end

    Given 'I had already connected my SAML SSO to an old account' do
      old_user_account = create_user(full_name: 'Lassie Fairy', email: 'l_fairy@gmx.de')
      context.assign :old_user, old_user_account
      data = Factory.create(:authorization, {
        user_id: old_user_account['id'],
        info: {email: old_user_account['email']},
      })
      Server[:account].api.rel(:authorizations).post(data).value!
    end

    When(/^I connect another "([^"]+)" account$/) do |provider|
      find('.another-profile').click_on provider.to_s
    end

    Then 'I have my work e-mail as secondary e-mail address' do
      find('#secondary-emails-show-button').click
      expect(page).to have_css('#secondary-emails-list')
      expect(page).to have_text('lassie@company.com')
    end

    Then 'Provider "SAML" is shown on my profile page twice' do
      click_on 'Profile'
      expect(page).to have_selector('[data-provider=saml]', count: 2)
    end

    Then 'I see an account connection success notice' do
      expect(page).to have_notice 'You can login to Xikolo using your SAML ID account from now.'
    end

    Then 'I am unexpectedly logged in to my old account' do
      send :'Given I am on the profile page'
      expect(page).to have_text('lassie@company.com')
      send :'Then Provider "SAML" is shown on my profile page twice'
    end
  end
end

Gurke.configure {|c| c.include Steps::SamlSso }
