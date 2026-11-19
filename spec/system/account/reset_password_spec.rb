# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Reset password', type: :system do
  let(:user) { create(:'account_service/user') }

  def reset_link_from_email(mail)
    url = mail.text_part.body.to_s.match(%r{https?://\S+}).to_s
    URI.parse(url).request_uri
  end

  before do
    visit '/'
    click_on 'Log in'
    click_on 'Forgot your password?'
  end

  it 'resets password via password forgot form' do
    expect(page).to have_link('Back to login', href: '/sessions/new')

    fill_in 'Your e-mail address', with: user.email

    perform_enqueued_jobs do
      click_button 'Request password reset'
      expect(page).to have_text(
        "We have sent a password reset e-mail to #{user.email}"
      )
    end

    email = find_mail_to(user.email)
    expect(email).to be_present
    expect(email.subject).to include('Password reset')

    visit reset_link_from_email(email)

    expect(page).to have_text('Reset password')
    expect(page).to have_link('Back to login', href: '/sessions/new')

    fill_in 'New password', with: 'new_secret123'
    fill_in 'Confirm password', with: 'new_secret123'
    click_button 'Set new password'

    expect(page).to have_text('Your password has been reset. Please log in again with your new password.')
    expect(page).to have_current_path('/sessions/new')

    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: 'new_secret123'
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
  end

  it 'fails with invalid email' do
    fill_in 'Your e-mail address', with: 'unknown@example.org'
    click_button 'Request password reset'

    expect(page).to have_text('Check if you entered the e-mail you registered with.')
  end

  it 'fails with empty email' do
    expect(page).to have_text('Reset password') # Wait for page load
    page.execute_script("document.querySelectorAll('input[required]').forEach(function(el) { el.removeAttribute('required'); })")
    fill_in 'Your e-mail address', with: ''
    click_button 'Request password reset'

    expect(page).to have_text("can't be blank")
  end

  it 'fails with non matching passwords' do
    fill_in 'Your e-mail address', with: user.email

    perform_enqueued_jobs do
      click_button 'Request password reset'
      expect(page).to have_text(
        "We have sent a password reset e-mail to #{user.email}"
      )
    end

    email = find_mail_to(user.email)
    visit reset_link_from_email(email)

    fill_in 'New password', with: 'new_secret123'
    fill_in 'Confirm password', with: '__wrong__'
    click_button 'Set new password'

    expect(page).to have_text('The passwords do not match')
  end

  it 'fails with empty passwords' do
    fill_in 'Your e-mail address', with: user.email

    perform_enqueued_jobs do
      click_button 'Request password reset'
      expect(page).to have_text(
        "We have sent a password reset e-mail to #{user.email}"
      )
    end

    email = find_mail_to(user.email)
    visit reset_link_from_email(email)

    page.execute_script("document.querySelectorAll('input[type=password]').forEach(function(el) { el.removeAttribute('required'); })")
    fill_in 'New password', with: ''
    fill_in 'Confirm password', with: ''
    click_button 'Set new password'

    expect(page).to have_text("can't be blank")
  end
end
