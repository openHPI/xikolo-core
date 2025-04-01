# frozen_string_literal: true

module Steps
  module AccountAuthentication
    Given 'I am not confirmed' do
      user = context.fetch :user

      Server[:account].api.rel(:user).patch({
        id: user.fetch('id'),
        confirmed: false,
      }).value!
    end

    Given(/^I have registered with "(.*)"$/) do |provider|
      context.with(:user) do |user|
        Server[:account].api.rel(:authorizations).post({
          user_id: user.fetch('id'),
          provider: provider.downcase,
          uid: '1234567', # Hardcoded to match OmniAuth stubs
          info: {email: user.fetch('email')},
        }).value!
      end
    end

    def goto_login
      visit '/'
      click_on 'Log in'
    end

    When 'I visit the login page', :goto_login
    Given 'I am on the login page', :goto_login

    def fill_in_email(email)
      fill_in 'E-mail', with: email
    end

    When 'I log in' do
      send :'When I visit the login page'
      send :'When I fill in my email address'
      send :'When I fill in my password'
      send :'When I submit my credentials'
    end

    When 'I fill in my email address' do
      fill_in_email context.fetch(:user).fetch('email')
    end

    When 'I fill in my upcase email address' do
      fill_in_email context.fetch(:user).fetch('email').upcase
    end

    def fill_in_password(pwd)
      fill_in 'Password', with: pwd, match: :prefer_exact
    end

    When 'I fill in my password' do
      fill_in_password context.fetch(:user).fetch('password')
    end

    When 'I fill in a wrong password' do
      fill_in_password '__wrong__'
    end

    When(/^I log in with "([^"]+)"$/) do |provider|
      find('#login-form').click_on provider.to_s
    end

    When 'I submit my account credentials' do
      fill_in 'Name', with: 'John Smith'
      send :'When I fill in my email address'
      send :'When I fill in my password'
      fill_in 'Repeat password', with: context.fetch(:user).fetch('password')
      click_on 'Register'
    end

    When 'I submit my credentials' do
      within('#login-form') do
        click_on 'Log in'
      end
    end

    def expect_login_state
      expect(page).to have_selector('[aria-label="Profile menu"]')
    end

    Then 'I am logged in into my profile', :expect_login_state
    Then 'I am logged in into my account', :expect_login_state

    def expect_logout_state
      expect(page).to have_link 'Log in'
    end

    Then(/^I am not logged in into my (profile|account)/, :expect_logout_state)
    Then 'I am logged out', :expect_logout_state

    Then 'I see a login failed notice' do
      expect(page).to have_notice 'Login failed'
    end

    Then 'I see a confirmation required notice' do
      expect(page).to have_notice 'This e-mail address has not been confirmed yet.'
    end

    Then(/^Provider "([\w\s]+)" is shown on my profile page$/) do |provider|
      click_on 'Profile'
      expect(page).to have_selector("[data-provider=#{provider.downcase}]")
    end
  end
end

Gurke.configure do |c|
  c.include Steps::AccountAuthentication
end
