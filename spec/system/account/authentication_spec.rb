# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Authentication', type: :system do
  let(:user) { create(:'account_service/user') }

  it 'signs in with valid credentials' do
    visit '/'
    click_on 'Log in'

    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: user.password
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
    expect(page).to have_current_path('/dashboard')
  end

  it 'signs in with valid case insensitive credentials' do
    visit '/'
    click_on 'Log in'

    fill_in 'E-mail', with: user.email.upcase
    fill_in 'Password', with: user.password
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
    expect(page).to have_current_path('/dashboard')
  end

  it 'fails log in with invalid credentials' do
    visit '/'
    click_on 'Log in'

    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: 'wrong-password'
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_no_css('[aria-label="Profile menu"]')
    expect(page).to have_text('Login failed. Please check your credentials.')
  end

  it 'signs out' do
    sign_in(user: user)
    visit '/dashboard'

    find('[aria-label="Profile menu"]').click
    click_on 'Log out'

    expect(page).to have_current_path('/')
    expect(page).to have_link('Log in')
  end

  it 'logs in with SAML SSO' do
    OmniAuth.config.add_mock(:saml,
      uid: '1234567',
      info: {name: user.full_name, email: user.email},
      credentials: {},
      extra: {session_index: '1122334455'})

    create(:'account_service/authorization', user:, provider: 'saml', uid: '1234567')

    visit '/'
    click_on 'Log in'

    within('#login-form') do
      click_on 'Single Sign-On (SSO)'
      click_on 'Single Sign-On (SAML)'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
    expect(page).to have_current_path('/dashboard')
  end
end
