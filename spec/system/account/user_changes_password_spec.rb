# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Change own password', type: :system do
  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user:)
    click_on('Profile')
  end

  it 'changes own password' do
    within('#changepassword') do
      click_on('Change password')
    end

    within('#form-changepassword') do
      fill_in 'Old password', with: user.password
      fill_in 'New password', with: 'new_secret123'
      fill_in 'Confirm password', with: 'new_secret123'

      click_on('Change password')
    end

    expect(page).to have_text('Your password has been successfully changed.')
  end

  it 'logs in with new password' do
    within('#changepassword') do
      click_on('Change password')
    end

    within('#form-changepassword') do
      fill_in 'Old password', with: user.password
      fill_in 'New password', with: 'new_secret123'
      fill_in 'Confirm password', with: 'new_secret123'

      click_on('Change password')
    end

    expect(page).to have_text('Your password has been successfully changed.')

    find('[aria-label="Profile menu"]').click
    click_on 'Log out'

    expect(page).to have_text 'You successfully logged out.'

    visit('/')

    click_on 'Log in'

    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: 'new_secret123'
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
  end
end
