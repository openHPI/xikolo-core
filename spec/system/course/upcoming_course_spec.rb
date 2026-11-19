# frozen_string_literal: true

require 'spec_helper'

describe 'Upcoming Course', type: :system do
  let(:user) { create(:'account_service/user') }
  let(:course) do
    create(:'course_service/course', :upcoming)
  end

  before do
    sign_in(user: user)
    enroll_in(course)
  end

  it 'shows a countdown and restricts access to content' do
    visit "/learn/#{course.course_code}"

    within('[data-testid="course-details-card"]') do
      expect(page).to have_text('Starts in')
      expect(page).to have_css('[data-controller="countdown"]')
    end

    visit "/learn/#{course.course_code}/resume"

    expect(page).to have_text('There is no public course content yet.')
    expect(page).to have_current_path("/learn/#{course.course_code}")
  end
end
