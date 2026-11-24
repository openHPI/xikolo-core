# frozen_string_literal: true

require 'spec_helper'

describe 'Course Resume function', type: :system do
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course: course) }
  let!(:items) do
    (1..5).map do |i|
      video = create(:video)
      create(:'course_service/item',
        section: section,
        title: "Video title #{i}",
        content: video)
    end
  end

  before do
    sign_in(user: user)
    enroll_in(course)
  end

  context 'Enter a course for the first time' do
    it 'redirects to the first items page' do
      visit dashboard_path
      within('.course-card', text: course.title) { click_on course.title }
      within('nav[aria-label="Course actions"]') { click_on 'Continue learning' }

      expect(page).to have_text(items.first.title)
    end
  end

  context 'Reenter the course at the last viewed item' do
    before do
      # I worked on some items
      visit "/learn/#{course.course_code}/items/#{items[0].id}"
      visit "/learn/#{course.course_code}/items/#{items[1].id}"
    end

    it 'redirects to the last visited items page' do
      visit dashboard_path
      within('.course-card', text: course.title) { click_on course.title }
      within('nav[aria-label="Course actions"]') { click_on 'Continue learning' }

      expect(page).to have_text(items[1].title)
    end

    %i[course_path course_progress_path course_announcements_path course_pinboard_index_path].each do |path_helper|
      it "continues learning at the last visited item from #{path_helper}" do
        visit public_send(path_helper, course.course_code)

        click_on 'Continue learning'

        expect(page).to have_current_path course_item_path(course.course_code, short_uuid(items[1].id))
        expect(page).to have_text items[1].title
      end
    end
  end
end
