# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Registration', type: :system do
  it 'registers with password' do
    visit '/'
    click_on 'Log in'
    click_on 'Create new account'

    fill_in 'First and Last Name', with: 'John Smith'
    fill_in 'Date of birth', with: '1990-01-20'
    select 'Teacher', from: 'Status'
    fill_in 'E-mail', with: 'john@xikolo.de'
    fill_in 'Password', with: 'secret123', match: :prefer_exact
    fill_in 'Repeat password', with: 'secret123'

    perform_enqueued_jobs do
      within('#registration-form') { click_on 'Register' }

      expect(page).to have_text 'Confirm your account'
    end

    expect(page).to have_text 'You will receive an email within the next few minutes to verify your account.'

    email = find_mail_to('john@xikolo.de')
    expect(email).to be_present
    expect(email.subject).to include('Welcome to')
    expect(email.text_part.body.decoded).to include('please confirm your e-mail address')
    expect(email.text_part.body.decoded).to include('Enroll for a course that interests you')

    confirmation_link = email.text_part.body.decoded.match(%r{(https?://\S+/account/confirm/\S+)})[1]
    visit confirmation_link

    expect(page).to have_link 'Log in'

    fill_in 'E-mail', with: 'john@xikolo.de'
    fill_in 'Password', with: 'secret123', match: :prefer_exact
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
    expect(page).to have_text 'My upcoming learning opportunities'
  end

  it 'registers with email notifications enabled' do
    visit '/'
    click_on 'Log in'
    click_on 'Create new account'

    fill_in 'First and Last Name', with: 'John Smith'
    fill_in 'Date of birth', with: '1990-01-20'
    select 'Teacher', from: 'Status'
    fill_in 'E-mail', with: 'john@xikolo.de'
    fill_in 'Password', with: 'secret123', match: :prefer_exact
    fill_in 'Repeat password', with: 'secret123'

    expect(page).to have_text 'I would like to receive email notifications from openHPI'
    check 'notification_emails', allow_label_click: true

    perform_enqueued_jobs do
      within('#registration-form') { click_on 'Register' }

      expect(page).to have_text 'Confirm your account'
    end

    user = AccountService::Email.find_by!(address: 'john@xikolo.de').user
    expect(user.preferences).to include(
      'notification.email.global' => 'true',
      'notification.email.news.announcement' => 'true',
      'notification.email.course.announcement' => 'true',
      'notification.email.pinboard.new_answer' => 'true'
    )
  end

  it 'registers without email notifications by default' do
    visit '/'
    click_on 'Log in'
    click_on 'Create new account'

    fill_in 'First and Last Name', with: 'John Smith'
    fill_in 'Date of birth', with: '1990-01-20'
    select 'Teacher', from: 'Status'
    fill_in 'E-mail', with: 'john@xikolo.de'
    fill_in 'Password', with: 'secret123', match: :prefer_exact
    fill_in 'Repeat password', with: 'secret123'

    perform_enqueued_jobs do
      within('#registration-form') { click_on 'Register' }

      expect(page).to have_text 'Confirm your account'
    end

    user = AccountService::Email.find_by!(address: 'john@xikolo.de').user
    expect(user.preferences).to eq({'notification.email.global' => 'false'})
  end

  it 'registers with selected language' do
    visit '/'
    click_on 'English'
    click_on 'Deutsch'
    click_on 'Anmelden'
    click_on 'Neues Benutzerkonto anlegen'

    fill_in 'Vor- und Nachname', with: 'John Smith'
    fill_in 'Geburtsdatum', with: '1990-01-20'
    select 'Lehrkraft', from: 'Status'
    fill_in 'E-Mail', with: 'john@xikolo.de'
    fill_in 'Passwort', with: 'secret123', match: :prefer_exact
    fill_in 'Passwort wiederholen', with: 'secret123'

    perform_enqueued_jobs do
      within('#registration-form') { click_on 'Registrieren' }

      expect(page).to have_text 'Bestätige dein Konto'
    end

    expect(page).to have_text 'Du erhältst innerhalb der nächsten Minuten eine E-Mail zur Verifizierung deines Kontos.'

    email = find_mail_to('john@xikolo.de')
    expect(email).to be_present
    expect(email.subject).to include('Willkommen bei')
    expect(email.text_part.body.decoded).to include('bestätigen Sie bitte Ihre E-Mail-Adresse')
    expect(email.text_part.body.decoded).to include('Melden Sie sich für einen Kurs an, der Sie interessiert')
  end
end
