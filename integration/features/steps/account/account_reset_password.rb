# frozen_string_literal: true

module Steps
  module AccountPasswordReset
    step 'I request a password reset with my email address' do
      fill_in 'e-mail address', with: context.fetch(:user)[:email]
      click_on 'Request password reset'
    end

    step 'I click on the password reset link' do
      open_email
      click_on 'Reset password'
    end

    When 'I assign a new password' do
      user = context.fetch(:user)
      user[:password] = 'far_more_secret'

      fill_in 'New password', with: user[:password], match: :prefer_exact
      fill_in 'Confirm password', with: user[:password], match: :prefer_exact

      click_on 'Set new password'

      expect(page).to have_content 'Your password has been reset. Please log in again with your new password.'
    end

    When 'I assign two different passwords' do
      user = context.fetch(:user)
      user[:password] = 'far_more_secret'

      fill_in 'New password', with: user[:password], match: :prefer_exact
      fill_in 'Confirm password', with: '__wrong__', match: :prefer_exact

      click_on 'Set new password'
    end

    When 'I assign a new empty password' do
      user = context.fetch(:user)
      user[:password] = 'far_more_secret'

      # Otherwise the browser wont even let me submit them
      page.execute_script("$('[type=password]').attr('required', false)")

      fill_in 'New password', with: '', match: :prefer_exact
      fill_in 'Confirm password', with: '', match: :prefer_exact

      click_on 'Set new password'
    end

    When 'I request a password reset with an invalid email address' do
      fill_in 'e-mail address', with: 'unknown@example.org'
      click_on 'Request password reset'
    end

    When 'I request a password reset with an empty email address' do
      page.execute_script("$('input[required]').attr('required', false)")

      fill_in 'e-mail address', with: ''
      click_on 'Request password reset'
    end

    Then 'I see a password reset notice' do
      expect(page).to have_notice "We have sent a password reset e-mail to #{context.fetch(:user)[:email]}."
    end

    Then 'I receive a password reset email' do
      open_email
      expect(page).to have_content 'password reset'
    end

    Then 'I am able to login with my new password' do
      user = context.fetch :user

      visit '/'
      click_on 'Log in'

      fill_in_email user[:email]
      fill_in_password user[:password]

      send :'When I submit my credentials'
      send :'Then I am logged in into my profile'
    end

    Then 'I see an error about a non-existing email address' do
      expect(page).to have_content 'Check if you entered the e-mail you registered with'
    end

    Then 'I see a form error' do
      expect(page).to have_selector '.has-error'
    end
  end
end

Gurke.configure do |c|
  c.include Steps::AccountPasswordReset
end
