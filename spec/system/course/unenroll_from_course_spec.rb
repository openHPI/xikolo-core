# frozen_string_literal: true

require 'spec_helper'

describe 'Unenroll from a course', type: :system do
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course: course) }
  let!(:item) do
    video = create(:video)
    create(:'course_service/item',
      section: section,
      title: 'A video item',
      content: video)
  end

  before do
    sign_in(user: user)
    enroll_in(course)
  end

  describe 'Unenroll from a course' do
    it 'allows the user to unenroll and confirms it' do
      click_on 'Un-enroll'

      # Redirected to dashboard and show confirmation
      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_text('You have been unenrolled.')
      expect(page).to have_no_css('.course-card', text: course.title)
    end
  end

  describe 'Keep data for re-enrollment' do
    it 'remembers item completion after unenrolling and re-enrolling' do
      # View item and Completed it
      within('[data-testid="course-details-card"]') do
        click_on 'Continue course'
      end

      expect(page).to have_text(item.title)

      click_on 'Back to course details'
      click_on 'Un-enroll'

      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_text('You have been unenrolled.')

      click_on 'Learn'

      within('.course-card', text: course.title) { click_on course.title }
      within('[data-testid="course-details-card"]') do
        click_on 'Enroll now'
      end
      expect(page).to have_text('You have been enrolled successfully.')
      visit "/learn/#{course.course_code}/progress"

      within('section[aria-labelledby="progress-header-title"]') do
        expect(page).to have_text '1 / 1'
      end
    end
  end
end
