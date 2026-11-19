# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Deleting a comment in a forum', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:student) { create(:'account_service/user') }
  let!(:topic) { create(:'pinboard_service/question', course_id: course.id, user_id: student.id) }
  let!(:answer) { create(:'pinboard_service/answer', question: topic, user_id: create(:'account_service/user').id) }

  context 'as course admin' do
    let(:admin) { create(:'account_service/user') }

    before do
      group = AccountService::Group.find_by!(name: "course.#{course.course_code}.admins")
      create(:'account_service/membership', user: admin, group:)
      create(:'course_service/enrollment', course:, user_id: admin.id)
    end

    it 'deletes a topic comment' do
      comment = create(:'pinboard_service/comment',
        commentable: topic,
        commentable_type: 'PinboardService::Question',
        user_id: create(:'account_service/user').id)

      sign_in(user: admin)
      visit course_path(course)
      click_on 'Forum'
      click_on topic.title

      within '.question-comments' do
        click_on 'delete'
      end

      within('[role=dialog][aria-modal=true]') do
        click_on 'Yes, sure'
      end

      expect(page).to have_current_path("/learn/#{course.course_code}/question/#{topic.id}")
      expect(page).to have_no_text comment.text
    end

    it 'deletes an answer comment' do
      comment = create(:'pinboard_service/comment',
        commentable: answer,
        commentable_type: 'PinboardService::Answer',
        user_id: create(:'account_service/user').id)

      sign_in(user: admin)
      visit course_path(course)
      click_on 'Forum'
      click_on topic.title

      within '.answer-comments' do
        click_on 'delete'
      end

      within('[role=dialog][aria-modal=true]') do
        click_on 'Yes, sure'
      end

      expect(page).to have_current_path("/learn/#{course.course_code}/question/#{topic.id}")
      expect(page).to have_no_text comment.text
    end
  end

  context 'as comment author' do
    before do
      sign_in(user: student)
      enroll_in(course)
    end

    it 'does not allow deleting own comments' do
      create(:'pinboard_service/comment',
        commentable: topic,
        commentable_type: 'PinboardService::Question',
        user_id: student.id)

      create(:'pinboard_service/comment',
        commentable: answer,
        commentable_type: 'PinboardService::Answer',
        user_id: student.id)

      visit course_path(course)
      click_on 'Forum'
      click_on topic.title

      within '.question-comments' do
        expect(page).to have_no_link('delete')
      end

      within '.answer-comments' do
        expect(page).to have_no_link('delete')
      end
    end
  end
end
