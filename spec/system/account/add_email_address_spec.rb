# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Add email address', type: :system do
  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user: user)
    click_on('Profile')
    click_on('Edit')
    click_on('Edit my e-mail')
  end

  it 'adds a new email address and confirms it' do
    perform_enqueued_jobs do
      fill_in 'Add a new e-mail address', with: 'john@example.com'
      click_button 'Save'

      expect(page).to have_text('We sent you a confirmation e-mail to john@example.com.')
    end

    email = find_mail_to('john@example.com')
    expect(email.subject).to include('confirm your e-mail address')
    expect(email.text_part.body.decoded).to include('you have added a new email address to your account on')
    expect(email.html_part.body.decoded).to include('Confirm e-mail')

    confirmation_link = email.text_part.body.decoded.match(%r{(http://\S+/account/confirm/\S+)})[1]
    visit confirmation_link

    expect(page).to have_text('Thank you for confirming your e-mail address.')
    expect(page).to have_current_path('/dashboard')
  end
end
