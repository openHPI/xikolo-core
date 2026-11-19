# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Deleting a topic in a forum', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:student) { create(:'account_service/user') }
  let!(:topic) { create(:'pinboard_service/question', course_id: course.id, user_id: student.id) }

  before do
    create(:'pinboard_service/answer', question: topic, user_id: create(:'account_service/user').id)
  end

  context 'as course admin' do
    let(:admin) { create(:'account_service/user') }

    before do
      group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
      create(:'account_service/membership', user: admin, group:)
      create(:'course_service/enrollment', course:, user_id: admin.id)
    end

    it 'deletes a topic' do
      sign_in(user: admin)
      visit course_path(course)
      click_on 'Forum'
      click_on topic.title

      within '.moderator' do
        click_on 'Delete'
      end

      within('[role=dialog][aria-modal=true]') do
        click_on 'Yes, sure'
      end

      expect(page).to have_text 'Sorry, nothing here yet.'
      expect(page).to have_no_text topic.title
    end
  end

  context 'as regular user' do
    before do
      sign_in(user: student)
      enroll_in(course)
    end

    it 'does not allow deleting the topic' do
      click_on 'Forum'
      click_on topic.title

      expect(page).to have_text('Add reply')
      expect(page).to have_no_css('.moderator')
    end
  end

  context 'when topic is deleted' do
    before do
      topic.update!(deleted: true)
    end

    it 'does not show the deleted topic in the forum' do
      sign_in(user: student)
      enroll_in(course)
      click_on 'Forum'

      expect(page).to have_text('Sorry, nothing here yet.')
      expect(page).to have_no_text topic.title
    end
  end
end
