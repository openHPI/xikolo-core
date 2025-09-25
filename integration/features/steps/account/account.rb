# frozen_string_literal: true

require 'active_support/hash_with_indifferent_access'

module Steps
  module Account
    def create_user(attrs = {})
      data = Factory.create(:user, attrs)

      user = Server[:account].api.rel(:users).post(data).value!
      user['password'] = data[:password]
      user
    end

    def create_email(attrs = {})
      user = context.fetch(:user)
      user.rel(:emails).post(attrs).value!
    end

    def create_treatment(attrs = {})
      data = Factory.create(:treatment, attrs)
      Server[:account].api.rel(:treatments).post(data).value!
    end

    def create_and_assign_consent(attrs = {})
      user = context.fetch(:user)
      treatment = context.fetch(:treatment)
      data = [attrs.merge(name: treatment['name'], consented: true)]
      Server[:account].api
        .rel(:user).get({id: user.fetch('id')}).value!
        .rel(:consents).patch(data).value!
    end

    def create_and_assign_user(attrs = {})
      context.assign :user, create_user(attrs)
    end

    def create_authorization(attrs = {})
      user = context.fetch(:user)
      data = Factory.create(:authorization, attrs.merge(user_id: user.fetch('id')))
      Server[:account].api.rel(:authorizations).post(data).value!
    end

    def enable_feature(name)
      user = context.fetch(:user)
      user.rel(:features).patch({name => true}).value!
    end

    Given(/I have the feature (.*) enabled/) do |name|
      enable_feature(name)
    end

    Given 'I am a confirmed user' do
      create_and_assign_user
    end

    Given 'I am an unconfirmed user' do
      create_and_assign_user confirmed: false
    end

    Given 'I am an administrator' do
      create_and_assign_user
      join_global_group 'xikolo.admins'
    end

    Given 'I am a GDPR administrator' do
      create_and_assign_user
      join_global_group 'xikolo.admins'
      join_global_group 'xikolo.gdpr_admins'
    end

    Given(/I am in the (.*) group/) do |group|
      join_global_group(group)
    end

    Given 'I am logged in' do
      user = context.fetch(:user)

      # Make sure we're logged out
      Capybara.reset_sessions!

      # Set session ID to be stored in xikolo-web session
      session = Server[:account].api.rel(:sessions).post({user: user['id']}).value!

      page.visit('/__session__')
      page.fill_in('session_id', with: session['id'])
      page.click_on('Save')
      expect(page).to have_content('Session ID changed')
    end

    Given 'the user has an additional confirmed email' do
      context.assign :email, create_email({address: 'example@example.com', confirmed: true})
    end

    Then 'I am logged in' do
      expect(page).to have_selector('[aria-label="Profile menu"]')
    end

    When 'I log out' do
      visit '/'
      find('[aria-label="Profile menu"]').click
      click_on 'Log out'
    end

    def log_in(user)
      click_on 'Log in'
      submit_my_login_credentials user
    end

    def submit_my_login_credentials(user = nil)
      user ||= context.fetch(:user)
      within '#login-form' do
        fill_in 'E-mail', with: user.fetch('email')
        fill_in 'Password', with: user.fetch('password')
        click_on 'Log in'
      end
      sleep 0.1
    end

    Given 'I submit my login credentials', :submit_my_login_credentials
    When 'I submit my login credentials', :submit_my_login_credentials

    Given 'I am confirmed, enrolled and logged in' do
      send :'Given I am a confirmed user'
      send :'Given I am enrolled in the active course'
      send :'Given I am logged in'
    end

    Given 'I am logged in as another user' do
      send :'Given there exists an additional user'
      user = context.fetch(:additional_user)
      context.assign :user, user, force: true # if another user is already logged in this fails without force
      enroll
      send :'Given I am logged in'
    end

    Given 'I am logged in as some other user' do
      user = create_user
      context.assign :user, user, force: true
      enroll
      send :'Given I am logged in'
    end

    Given 'I am logged in as a confirmed user' do
      create_and_assign_user
      send :'Given I am logged in'
    end

    Given 'there exists an additional user' do
      context.assign :additional_user, create_user(full_name: 'Jane Austen')
    end

    Given 'there is a third user' do
      context.assign :third_user, create_user
    end

    Given 'there exist some users' do
      users = Factory.create_list(:user, 10)
      users.map! do |data|
        Server[:account].api.rel(:users).post(data).then do |user|
          data.each_pair {|key, value| user[key] ||= value }
          user
        end
      end
      users.map!(&:value!)

      context.assign :users, users
    end

    When 'I am logged in as another user' do
      send :'Given I am logged in as another user'
    end

    Given 'I am logged in as admin' do
      send :'Given I am an administrator'
      send :'Given I am logged in'
    end

    Given 'I am logged in as GDPR admin' do
      send :'Given I am a GDPR administrator'
      send :'Given I am logged in'
    end

    Given(/the (.*) group exists/) do |group|
      Server[:account].api.rel(:groups).post({
        name: group,
        description: "The #{group} group",
      }).value!
    end
  end
end

Gurke.configure {|c| c.include Steps::Account }
