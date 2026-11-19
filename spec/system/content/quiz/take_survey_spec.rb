# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Take a survey', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:quiz) { create(:'quiz_service/quiz', unlimited_attempts: true) }
  let(:item) { create(:'course_service/item', :quiz, section:, content_id: quiz.id, exercise_type: 'survey') }
  let(:question) { create(:'quiz_service/multiple_choice_question', quiz:) }
  let(:user) { create(:'account_service/user') }

  before do
    create(:'quiz_service/text_answer', question:, text: 'Some Answer')
    item
    sign_in(user:)
    enroll_in(course)
  end

  it 'takes the survey' do
    visit "/learn/#{course.course_code}/items/#{short_uuid(item.id)}"
    choose 'Some Answer'
    click_on 'quiz_submit_button'
    expect(page).to have_text \
      'Thank you for your participation in this survey. Your feedback is ' \
      'valuable to improve the learning experience!'
    expect(page).to have_text 'Retake quiz'
  end

  context 'when the submission deadline has passed' do
    let(:item) do
      create(:'course_service/item', :quiz, section:, content_id: quiz.id,
        exercise_type: 'survey', submission_deadline: 2.days.ago)
    end

    it 'shows the deadline passed message' do
      visit "/learn/#{course.course_code}/items/#{short_uuid(item.id)}"
      expect(page).to have_text \
        'You cannot enter any new submissions, because the submission ' \
        'deadline has already passed.'
      expect(page).to have_no_text 'Retake quiz'
    end
  end
end
