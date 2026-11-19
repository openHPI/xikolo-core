# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Redirect after login', type: :system do
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:'course_service/course', :active) }

  it 'redirects to dashboard by default' do
    visit '/'
    click_on 'Log in'

    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: user.password
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
    expect(page).to have_current_path('/dashboard')
  end

  it 'stays on course details page when logging in there' do
    visit "/learn/#{course.course_code}"
    click_on 'Log in'

    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: user.password
    within('#login-form') do
      click_on 'Log in'
    end

    expect(page).to have_css('[aria-label="Profile menu"]')
    expect(page).to have_current_path("/learn/#{course.course_code}")
  end
end
