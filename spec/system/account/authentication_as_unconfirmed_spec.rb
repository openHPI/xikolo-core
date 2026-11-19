# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Authentication as unconfirmed user', type: :system do
  let(:user) { create(:'account_service/user', :unconfirmed) }

  it 'fails login when not confirmed' do
    visit '/'
    click_on 'Log in'

    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: user.password
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_no_css('[aria-label="Profile menu"]')
    expect(page).to have_text('has not been confirmed yet')
  end
end
