# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Authentication via registration form', type: :system do
  let(:user) { create(:'account_service/user') }

  before do
    visit '/'
  end

  it 'logs in via registration form' do
    click_on 'Log in'
    click_on 'Create new account'

    fill_in 'First and Last Name', with: 'John Smith'
    fill_in 'Date of birth', with: '01.01.1990'
    select 'Teacher', from: 'Status'
    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: user.password
    fill_in 'Repeat password', with: user.password

    within('#registration-form') { click_button 'Register' }

    expect(page).to have_css('[aria-label="Profile menu"]')
  end
end
