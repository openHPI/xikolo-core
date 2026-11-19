# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Mark topic sticky', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:admin) { create(:'account_service/user') }
  let(:student) { create(:'account_service/user') }

  before do
    group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
    create(:'account_service/membership', user: admin, group: group)
  end

  describe 'as a course admin' do
    before do
      sign_in(user: admin)
      enroll_in(course)
    end

    it 'marks an existing topic sticky' do
      topics = create_list(:'pinboard_service/question', 6, course_id: course.id)
      target_topic = topics.first

      visit "/learn/#{course.course_code}/question/#{target_topic.id}"

      find('.question-edit').click
      within "#edit_form_xikolo_pinboard_question_#{target_topic.id}" do
        find('label', text: 'Sticky').click
      end

      click_on 'Save changes'

      click_on 'Forum'

      # The sticky topic should be on top
      first_question = first('.pinboard-question')
      expect(first_question).to have_text(target_topic.title)
      within first_question do
        expect(page).to have_css('.fa-thumbtack')
      end
    end

    it 'creates a sticky topic as moderator' do
      visit "/learn/#{course.course_code}/pinboard"

      find_by_id('new-topic-button').click

      fill_in 'Title', with: 'Sticky Announcment'
      fill_markdown_editor('Text', with: 'Important stuff!')

      within '#new_xikolo_pinboard_question' do
        find('label', text: 'Sticky').click
      end

      click_on 'Post new topic'

      expect(page).to have_text('Sticky Announcment')

      expect(first('.question-title')).to have_text('Sticky Announcment')
      expect(first('.pinboard-question')[:class]).to match(/(\s|^)sticky(\s|$)/)
    end
  end

  describe 'as a student' do
    before do
      sign_in(user: student)
      enroll_in(course)
    end

    it 'cannot mark a new topic sticky' do
      visit "/learn/#{course.course_code}/pinboard"

      find_by_id('new-topic-button').click

      within '#new_xikolo_pinboard_question' do
        expect(page).to have_no_text('Sticky')
      end
    end
  end
end
