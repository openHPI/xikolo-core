# frozen_string_literal: true

require 'spec_helper'

describe 'Account: SAML SSO', type: :system do
  it 'registers a new account via SAML SSO' do
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

    perform_enqueued_jobs do
      click_on 'Continue with new account'

      expect(page).to have_css('[aria-label="Profile menu"]')
    end

    expect(page).to have_current_path('/dashboard')

    click_on 'Profile'
    expect(page).to have_css('[data-provider=saml]')

    email = find_mail_to('new-sso-user@example.com')
    expect(email).to be_present
    expect(email.subject).to include('Welcome to')
    expect(email.text_part.body.decoded).to include('Enroll for a course that interests you')
    expect(email.text_part.body.decoded).not_to include('please confirm your e-mail address')
    expect(email.text_part.body.decoded).not_to include('Confirm-email')
  end

  it 'connects SAML SSO to existing account with matching email' do
    user = create(:'account_service/user', full_name: 'Lassie Fairy')
    user.primary_email.update!(address: 'lassie@company.com')
    user.reload

    create(:'account_service/authorization', user: user, provider: 'saml', uid: 'P123456')

    OmniAuth.config.add_mock(:saml,
      uid: '1234567',
      info: {name: 'Lassie Fairy', email: 'lassie@company.com'},
      credentials: {},
      extra: {session_index: '1122334455'})

    visit '/'
    click_on 'Log in'

    within('#login-form') do
      click_on 'Single Sign-On (SSO)'
      click_on 'Single Sign-On (SAML)'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
    expect(page).to have_current_path('/dashboard')
    expect(page).to have_text 'using your SAML ID account from now.'

    click_on 'Profile'
    expect(page).to have_css('[data-provider=saml]', count: 2)
  end

  it 'connects SAML SSO to existing account with matching email while being logged in' do
    user = create(:'account_service/user', full_name: 'Lassie Fairy')
    user.primary_email.update!(address: 'lassie@company.com')
    user.reload

    create(:'account_service/authorization', user: user, provider: 'saml', uid: 'P123456')

    sign_in(user: user)

    click_on 'Profile'

    OmniAuth.config.add_mock(:saml,
      uid: '1234567',
      info: {name: 'Lassie Fairy', email: 'lassie@company.com'},
      credentials: {},
      extra: {session_index: '1122334455'})

    within('.another-profile') do
      click_on 'Single Sign-On (SAML)'
    end

    expect(page).to have_text 'using your SAML ID account from now.'
    expect(page).to have_css('[data-provider=saml]', count: 2)
  end

  it 'connects SAML SSO to existing account with different e-mail address' do
    user = create(:'account_service/user', full_name: 'Lassie F.')
    user.primary_email.update!(address: 'lassie_f@web.de')
    user.reload

    OmniAuth.config.add_mock(:saml,
      uid: '1234567',
      info: {name: 'Lassie Fairy', email: 'lassie@company.com'},
      credentials: {},
      extra: {session_index: '1122334455'})

    visit '/'
    click_on 'Log in'

    within('#login-form') do
      click_on 'Single Sign-On (SSO)'
      click_on 'Single Sign-On (SAML)'
    end

    click_on 'Login and connect to existing account'

    expect(page).to have_text('Please login to your existing openHPI account')
    expect(page).to have_current_path(new_session_path)

    within('#login-form') do
      fill_in 'E-mail', with: user.email
      fill_in 'Password', with: user.password
      click_on 'Log in'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
    expect(page).to have_current_path('/dashboard')
    expect(page).to have_text 'using your SAML ID account from now.'

    click_on 'Profile'
    expect(page).to have_css('[data-provider=saml]')
  end

  it 'unexpectedly logs in to old account when connecting already connected SAML SSO' do
    user = create(:'account_service/user', full_name: 'Lassie F.')
    user.primary_email.update!(address: 'lassie_f@web.de')
    user.reload

    old_user = create(:'account_service/user', full_name: 'Lassie Fairy')
    old_user.primary_email.update!(address: 'lassie@company.com')
    old_user.reload
    create(:'account_service/authorization', user: old_user, provider: 'saml', uid: 'P123456')

    sign_in(user: user)

    click_on 'Profile'

    OmniAuth.config.add_mock(:saml,
      uid: '1234567',
      info: {name: 'Lassie Fairy', email: 'lassie@company.com'},
      credentials: {},
      extra: {session_index: '1122334455'})

    within('.another-profile') do
      click_on 'Single Sign-On (SAML)'
    end

    expect(page).to have_text('lassie@company.com')
    expect(page).to have_css('[data-provider=saml]', count: 2)
  end

  it 'connects SAML SSO to existing account with different e-mail address while being logged in' do
    user = create(:'account_service/user', full_name: 'Lassie F.')
    user.primary_email.update!(address: 'lassie_f@web.de')
    user.reload

    sign_in(user: user)

    click_on 'Profile'

    OmniAuth.config.add_mock(:saml,
      uid: '1234567',
      info: {name: 'Lassie Fairy', email: 'lassie@company.com'},
      credentials: {},
      extra: {session_index: '1122334455'})

    within('.another-profile') do
      click_on 'Single Sign-On (SAML)'
    end

    expect(page).to have_text 'using your SAML ID account from now.'
    expect(page).to have_css('[data-provider=saml]', count: 1)
  end
end
