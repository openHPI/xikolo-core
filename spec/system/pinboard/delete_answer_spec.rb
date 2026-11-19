# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Deleting an answer in a forum', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:teacher) { create(:'account_service/user', :admin) }
  let(:student) { create(:'account_service/user') }
  let!(:topic) { create(:'pinboard_service/question', course_id: course.id, user_id: student.id) }

  before do
    create(:'pinboard_service/answer', question: topic, user_id: student.id, text: 'Answer Text')
  end

  it 'allows teacher to delete an answer' do
    sign_in(user: teacher)
    visit "/learn/#{course.course_code}/question/#{topic.id}"

    expect(page).to have_text('Answer Text')

    within '.qa-box.answer' do
      find('span.action', text: /Delete|delete/).click
    end

    click_on 'Yes, sure'

    expect(page).to have_current_path("/learn/#{course.course_code}/question/#{topic.id}")
    expect(page).to have_no_text('Answer Text')
  end

  it 'does not allow author to delete the answer' do
    sign_in(user: student)
    enroll_in(course)

    visit "/learn/#{course.course_code}/question/#{topic.id}"

    expect(page).to have_text('Answer Text')

    within '.qa-box.answer' do
      expect(page).to have_no_css('span.action', text: /Delete|delete/)
    end
  end
end
