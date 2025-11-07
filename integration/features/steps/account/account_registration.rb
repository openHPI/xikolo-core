# frozen_string_literal: true

module Steps
  module AccountRegistration
    def account_details
      {
        'email' => 'john@xikolo.de',
        'date_of_birth' => '1990-01-20',
        'password' => 'secret123',
        'full_name' => 'John Smith',
        'status' => 'other',
      }
    end

    When 'I submit my account details' do
      data = account_details
      context.assign :user, data

      fill_in 'Name', with: data['full_name']
      fill_in 'Date of birth', with: data['date_of_birth'].to_s
      select 'Teacher', from: 'Status'
      fill_in 'E-mail address', with: data['email']
      fill_in 'Password', with: data['password'], match: :prefer_exact
      fill_in 'Repeat password', with: data['password']
      click_on 'Register for'
    end

    When 'I submit my account details on German interface' do
      data = account_details
      context.assign :user, data

      fill_in 'Ihr Name', with: data['full_name']
      fill_in 'Geburtsdatum', with: data['date_of_birth'].to_s
      select 'Lehrkraft', from: 'Status'
      fill_in 'Ihre E-Mail-Adresse', with: data['email']
      fill_in 'Passwort', with: data['password'], match: :prefer_exact
      fill_in 'Passwort (Wiederholung)', with: data['password']
      click_on 'registrieren'
    end

    Then 'I see an email confirmation message' do
      expect(page).to have_content 'Please verify your account'
      expect(page).to have_content 'You will receive an email for verification in the next few minutes.'
    end

    Then 'I see an email confirmation message in German' do
      expect(page).to have_content 'Bitte aktivieren Sie Ihr Benutzerkonto'
      expect(page).to have_content 'Zur Bestätigung Ihrer E-Mail-Adresse werden Sie zeitnah eine E-Mail erhalten.'
    end

    Then 'I receive a welcome email with a link to confirm my email address' do
      send :'Then I receive a welcome email in English with a link to confirm my email address'
    end

    def visit_email_view
      user  = context.fetch :user
      email = fetch_emails(to: user.fetch('email')).last

      open_email email
    end

    def visit_emails_view
      email = fetch_emails(to: 'john@example.com').last

      open_email email
    end

    Then 'I receive a welcome email in English with a link to confirm my email address' do
      visit_email_view

      expect(page).to have_content 'Welcome to Xikolo'
      expect(page).to have_content 'please confirm your e-mail address'
      expect(page).to have_content 'Enroll for a course that interests you'
    end

    Then 'I receive a welcome email in English with a link to confirm my new email address' do
      visit_emails_view

      expect(page).to have_content 'Confirm your e-mail'
      expect(page).to have_content 'you have added a new email address to your account on Xikolo'
    end

    Then 'I receive a welcome email in German with a link to confirm my email address' do
      visit_email_view

      expect(page).to have_content 'Willkommen bei Xikolo'
      expect(page).to have_content 'bestätigen Sie bitte Ihre E-Mail-Adresse'
      expect(page).to have_content 'Melden Sie sich für einen Kurs an, der Sie interessiert'
    end

    Then 'I receive a welcome email without a link to confirm my email address' do
      open_email fetch_emails(to: nil).last # SSO stubs are hardcoded for different email addresses

      expect(page).to have_content 'Welcome to Xikolo'
      expect(page).to have_content 'Enroll for a course that interests you'

      expect(page).not_to have_content 'please confirm your e-mail address'
      expect(page).not_to have_content 'Confirm-email'
    end

    When 'I follow the email confirmation link' do
      click_on 'Confirm e-mail'
    end

    When 'I register for a new account' do
      click_on 'Create new account'

      send :'When I submit my account details'

      user = context.fetch :user
      open_email fetch_emails(to: user.fetch('email')).last

      send :'When I follow the email confirmation link'
    end

    When 'I decide to continue with a new account' do
      click_on 'Continue with new account'
    end

    When 'I decide to connect SSO login with my existing account' do
      click_on 'Login and connect to existing account'
    end
  end
end

Gurke.configure do |c|
  c.include Steps::AccountRegistration
end
