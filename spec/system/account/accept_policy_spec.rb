# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Accept policy on login', type: :system do
  let(:user) { create(:'account_service/user') }

  before do
    create(:'account_service/policy', version: 4)
  end

  it 'accepts policy on password login' do
    visit '/'
    click_on 'Log in'

    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: user.password
    within('#login-form') do
      click_on 'Log in'
    end

    click_on 'Proceed'

    expect(page).to have_css('[aria-label="Profile menu"]')
  end

  context 'with SAML provider' do
    before do
      OmniAuth.config.add_mock(:saml,
        uid: '1234567',
        info: {name: user.full_name, email: user.email},
        credentials: {},
        extra: {session_index: '1122334455'})
    end

    it 'accepts policy on SAML sign-up' do
      OmniAuth.config.add_mock(:saml,
        uid: '1234567',
        info: {name: 'New SSO User', email: 'new-sso-user@example.com'},
        credentials: {},
        extra: {session_index: '1122334455'})

      visit '/'
      click_on 'Log in'

      within('#login-form') do
        click_on 'Single Sign-On (SSO)'
        click_on 'Single Sign-On (SAML)'
      end

      click_on 'Continue with new account'
      click_on 'Proceed'

      expect(page).to have_css('[aria-label="Profile menu"]')
    end

    it 'accepts policy on SAML login' do
      create(:'account_service/authorization', user:, provider: 'saml', uid: '1234567')

      visit '/'
      click_on 'Log in'

      within('#login-form') do
        click_on 'Single Sign-On (SSO)'
        click_on 'Single Sign-On (SAML)'
      end

      click_on 'Proceed'

      expect(page).to have_css('[aria-label="Profile menu"]')
    end

    it 'no need to accept policy twice (SAML SSO)' do
      user.update(accepted_policy_version: 4)
      create(:'account_service/authorization', user:, provider: 'saml', uid: '1234567')

      visit '/'
      click_on 'Log in'

      within('#login-form') do
        click_on 'Single Sign-On (SSO)'
        click_on 'Single Sign-On (SAML)'
      end

      expect(page).to have_css('[aria-label="Profile menu"]')
      expect(page).to have_no_button('Proceed')
    end
  end

  it 'no need to accept policy twice' do
    user.update(accepted_policy_version: 4)

    visit '/'
    click_on 'Log in'

    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: user.password
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
    expect(page).to have_no_button('Proceed')
  end
end
