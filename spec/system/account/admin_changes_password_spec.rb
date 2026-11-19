# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Admin changes password', type: :system do
  it 'changes user password' do
    sign_in(user: create(:'account_service/user', :gdpr_admin))
    visit "/users/#{create(:'account_service/user').id}"
    fill_in 'Password', with: 'new-secret123'
    click_button 'Change password'

    expect(page).to have_text('Your password has been successfully changed')
  end

  it 'logs in with new password' do
    user = create(:'account_service/user')
    sign_in(user:)
    visit profile_path

    click_on 'Change password'

    fill_in 'Old password', with: attributes_for(:'account_service/user').fetch(:password)
    fill_in 'New password', with: 'new-secret123'
    fill_in 'Confirm password', with: 'new-secret123'
    click_button 'Change password'

    expect(page).to have_text('Your password has been successfully changed')

    find('[aria-label="Profile menu"]').click
    click_on 'Log out'

    expect(page).to have_text('You successfully logged out.')

    click_on 'Log in'

    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: 'new-secret123'
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
  end
end
