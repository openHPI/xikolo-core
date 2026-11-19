# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Mark as completed', type: :system do
  let(:user) { create(:'account_service/user') }
  let(:active_course) { create(:'course_service/course', :active, title: 'Active Course') }
  let(:self_paced_course) { create(:'course_service/course', :self_paced, title: 'Self-paced Course') }

  before do
    create(:enrollment, course: active_course, user_id: user.id)
    create(:enrollment, course: self_paced_course, user_id: user.id)
    sign_in(user:)
  end

  it 'shows manual completion on course details for active and self-paced courses' do
    [active_course, self_paced_course].each do |course|
      visit course_path(course.course_code)

      within('[data-testid="course-details-card"]') do
        expect(page).to have_link 'Mark as completed'
      end
    end
  end

  it 'marks a course as completed through its details page' do
    visit course_path(self_paced_course.course_code)
    within('[data-testid="course-details-card"]') do
      click_on 'Mark as completed'
    end

    expect(page).to have_text 'Are you sure?'
    within('[role=dialog][aria-modal=true]') do
      click_on 'Yes, sure'
    end
    expect(page).to have_no_css '.util-modal__frame'
    expect(page).to have_text 'The course was successfully marked as completed.'

    within('.course-group', text: 'My completed learning opportunities') do
      within('.course-card', text: 'Self-paced Course') do
        expect(page).to have_text 'Completed'
      end
    end
  end
end
