# frozen_string_literal: true

require 'spec_helper'

describe 'Course navigation', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }

  before { sign_in(user: user) }

  context 'when enrolled' do
    before { enroll_in(course) }

    it 'displays course navigation and hides teacher navigation for enrolled students' do
      visit course_path(course)

      within('header') do
        expect(page).to have_link 'Details'
        expect(page).to have_link 'Progress'
      end
      expect(page).to have_no_css('#teacher-nav')
    end

    it 'shows the number of unread announcements until they are read' do
      create_list(:'news_service/news', 2, :published, course_id: course.id)

      visit course_path(course)
      within('header') { expect(page).to have_link 'Announcements (2 unread)' }

      within('header') { click_on 'Announcements' }
      expect(page).to have_current_path("/learn/#{course.course_code}/announcements")

      visit course_path(course)

      within('header') do
        expect(page).to have_link 'Announcements'
        expect(page).to have_no_text 'unread'
      end
    end
  end

  context 'when not enrolled' do
    before { visit course_path(course) }

    it 'locks the tabs and explains how to unlock them' do
      within('header') do
        expect(page).to have_no_link 'Forum'
        click_on 'Forum'
      end

      expect(page).to have_text 'Enroll in this course to unlock this feature.'
    end
  end
end
