# frozen_string_literal: true

require 'spec_helper'

describe 'Delete a course', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:admin) { create(:'account_service/user', :admin) }

  before do
    sign_in(user: admin)
  end

  it 'allows a global course manager to remove a course' do
    visit edit_course_path(course)

    click_on 'Delete course'

    within('[role=dialog][aria-modal=true]') do
      click_on 'Yes, sure'
    end

    pending 'CourseService::Course::Destroy calls destroy_context!' \
            'that is not implimented in account_service.' \
            'Destruction will work in production with a silent failure in ' \
            'the context destruction.'

    expect(page).to have_text('The course has been deleted.')
    expect(page).to have_current_path(admin_courses_path)
    expect(page).to have_text('All Learning Units')
    expect(page).to have_no_text(course.course_code)
    expect(page).to have_no_text(course.title)
  end
end
