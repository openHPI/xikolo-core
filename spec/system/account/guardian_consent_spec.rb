# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Guardian consent', type: :system do
  describe 'when registering' do
    before do
      visit '/account/new'

      fill_in 'First and Last Name', with: 'John Smith'
      select 'Teacher', from: 'Status'
      fill_in 'E-mail', with: 'john@xikolo.de'
      fill_in 'Password', with: 'secret123', match: :prefer_exact
      fill_in 'Repeat password', with: 'secret123'
    end

    it 'replaces the privacy agreement while the birthdate makes the user underage' do
      expect(page).to have_no_field 'user_guardian_consent'
      expect(page).to have_text 'you agree to the terms of our privacy policy'

      fill_in 'Date of birth', with: 12.years.ago.to_date
      expect(page).to have_field 'user_guardian_consent'
      expect(page).to have_no_text 'you agree to the terms of our privacy policy'

      fill_in 'Date of birth', with: 30.years.ago.to_date
      expect(page).to have_no_field 'user_guardian_consent'
      expect(page).to have_text 'you agree to the terms of our privacy policy'
    end

    it 'is recorded for an underage user who confirms it' do
      fill_in 'Date of birth', with: 12.years.ago.to_date
      check 'user_guardian_consent', allow_label_click: true
      within('#registration-form') { click_on 'Register' }

      expect(page).to have_text 'Confirm your account'
      expect(AccountService::Email.find_by(address: 'john@xikolo.de').user.guardian_consent_at)
        .to be_within(1.minute).of(Time.zone.now)
    end
  end

  describe 'as an underage user who registered before it was required' do
    let(:user) { create(:'account_service/user', completed_profile: true, born_at: 12.years.ago) }
    let(:password) { attributes_for(:'account_service/user').fetch(:password) }

    # The shared `sign_in` helper waits for the dashboard, which this user is
    # interrupted on the way to, so the log in is done here instead.
    before do
      visit '/'
      click_on 'Log in'

      within '#login-form' do
        fill_in 'E-mail', with: user.primary_email.address
        fill_in 'Password', with: password
        click_on 'Log in'
      end
    end

    it 'has to be ticked before the user can continue, and is asked for only once' do
      expect(page).to have_text 'Disclaimer under 16 years old'

      check 'guardian_consent', allow_label_click: true
      click_on 'Proceed'
      expect(page).to have_text 'My upcoming learning opportunities'

      visit '/dashboard'
      expect(page).to have_text 'My upcoming learning opportunities'
    end
  end
end
