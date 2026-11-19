# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Report a post', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:question) { create(:'pinboard_service/question', course_id: course.id, user_id: create(:'account_service/user').id) }

  before do
    create(:'pinboard_service/answer', question:, user_id: create(:'account_service/user').id)
    create(:'pinboard_service/comment',
      commentable: question,
      commentable_type: 'PinboardService::Question',
      user_id: create(:'account_service/user').id)
    sign_in
    enroll_in(course)
    click_on 'Forum'
    click_on question.title
  end

  it 'reports a topic' do
    find('[data-test-id="question-report"]').click
    within('[role=dialog][aria-modal=true]') do
      click_on 'Yes, sure'
    end

    expect(page).to have_text 'Your report was received successfully'
  end

  it 'reports a topic twice' do
    2.times do
      find('[data-test-id="question-report"]').click

      within('[role=dialog][aria-modal=true]') do
        click_on 'Yes, sure'
      end

      expect(page).to have_text 'Your report was received successfully'
    end
  end

  it 'reports an answer' do
    find('[data-test-id="answer-report"]').click
    within('[role=dialog][aria-modal=true]') do
      click_on 'Yes, sure'
    end

    expect(page).to have_text 'Your report was received successfully'
  end

  it 'reports a comment' do
    find('[data-test-id="comment-report"]').click
    within('[role=dialog][aria-modal=true]') do
      click_on 'Yes, sure'
    end

    expect(page).to have_text 'Your report was received successfully'
  end
end
