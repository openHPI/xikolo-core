# frozen_string_literal: true

require 'spec_helper'

describe 'Enroll in Course', type: :system do
  include ActiveJob::TestHelper

  let(:user) { create(:'account_service/user') }

  let!(:course) { create(:'course_service/course', :active, welcome_mail: 'Welcome to the course') }

  it 'allows a logged in user to enroll' do
    sign_in(user:)
    click_on 'Learn'

    perform_enqueued_jobs(only: NotificationService::SendCourseWelcomeEmailJob) do
      within('.course-card', text: course.title) { click_on course.title }
      within('nav[aria-label="Course actions"]') { click_on 'Enroll for the course' }

      expect(page).to have_text 'You have been enrolled successfully.'
    end

    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end

  it 'allows a non-logged in user to enroll after logging in' do
    visit courses_path

    within('.course-card', text: course.title) { click_on course.title }
    within('nav[aria-label="Course actions"]') { click_on 'Enroll for the course' }

    expect(page).to have_text 'Please log in to proceed.'
    fill_in 'E-mail', with: user.email
    fill_in 'Password', with: attributes_for(:'account_service/user').fetch(:password)

    perform_enqueued_jobs(only: NotificationService::SendCourseWelcomeEmailJob) do
      click_button 'Log in'

      expect(page).to have_text 'You have been enrolled successfully.'
    end

    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end

  context 'from the course details' do
    let(:section) { create(:'course_service/section', course:) }
    let(:richtext) { create(:'course_service/richtext', course:) }
    let(:item) { create(:'course_service/item', section:, content_type: 'rich_text', content_id: richtext.id) }

    before do
      item
      sign_in(user:)
      visit course_path(course.course_code)
    end

    it 'allows a logged in user to enroll and start learning' do
      click_on 'Enroll for the course'
      expect(page).to have_text 'You have been enrolled successfully.'

      click_on 'Continue learning'
      expect(page).to have_current_path course_item_path(course.course_code, short_uuid(item.id))
      expect(page).to have_text item.title
    end
  end
end
