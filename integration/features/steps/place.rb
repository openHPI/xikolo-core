# frozen_string_literal: true

module PlaceSteps
  Given 'I am on the homepage' do
    visit '/'
  end

  When 'I am on the homepage' do
    visit '/'
  end

  Given 'I am on a page that does not exist' do
    visit '/courses/abcd'
  end

  Given 'I am on the dashboard page' do
    visit '/dashboard'
  end

  Given 'I am on the documents admin page' do
    visit '/documents'
  end

  Given 'I am on the new user test page' do
    visit '/user_tests'
    click_on 'New User Test'
  end

  When 'I am on the dashboard page' do
    visit '/dashboard'
    expect(page).to have_content('My upcoming courses')
  end

  When 'I am on the dashboard achievements page' do
    visit '/dashboard/achievements'
  end

  When 'I am on the dashboard documents page' do
    visit '/dashboard/documents'
  end

  When 'I reload the page' do
    visit current_path
  end

  When 'I open the login page' do
    click_on 'Log in'
  end

  Given 'I am on the registration page' do
    visit '/'
    click_on 'Log in'
    click_on 'Create new account'
  end

  Given 'I am on the password reset page' do
    visit '/'
    click_on 'Log in'
    click_on 'Forgot your password?'
  end

  Given 'I am browsing my notification settings' do
    visit '/preferences'
  end

  Then 'I am on the dashboard page' do
    expect(page).to have_current_path '/dashboard', ignore_query: true
  end

  Then 'I am on the home page' do
    expect(page).to have_current_path '/'
  end

  Then 'I am on the login page' do
    expect(page).to have_current_path '/sessions/new'
  end

  Then 'I am on the profile page' do
    expect(page).to have_current_path '/dashboard/profile'
  end

  Then 'I am on the profile edit page' do
    expect(page).to have_current_path '/dashboard/profile/edit'
  end

  Then 'I am on the profile picture edit page' do
    expect(page).to have_current_path '/dashboard/profile/edit_avatar'
  end

  Then 'I am on the profile edit email page' do
    expect(page).to have_current_path '/dashboard/profile/edit_email'
  end

  Then 'I should be on the profile settings page' do
    expect(page).to have_current_path '/preferences'
  end
end

Gurke.config.include PlaceSteps
