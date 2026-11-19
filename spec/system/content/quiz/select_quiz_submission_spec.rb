# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Show the latest quiz submission', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:quiz) { create(:'quiz_service/quiz', allowed_attempts: 2) }
  let(:item) do
    create(:'course_service/item', :quiz,
      section:, content_id: quiz.id, title: 'An Example Item',
      max_dpoints: 30)
  end
  let(:question) do
    create(:'quiz_service/multiple_answer_question',
      quiz:,
      text: 'What is the Internet?',
      points: 3,
      shuffle_answers: false)
  end
  let(:user) { create(:'account_service/user') }

  before do
    create(:'quiz_service/text_answer',
      question:,
      correct: true,
      text: 'The Internet is a global system of interconnected computer networks that use the standard Internet protocol suite (TCP/IP) to serve several billion users worldwide.',
      position: 1)
    create(:'quiz_service/text_answer',
      question:,
      correct: false,
      text: 'The Internet consists of cookies.',
      position: 2)

    sign_in(user:)
    enroll_in(course)
  end

  def enter_quiz_form
    visit "/learn/#{course.course_code}/items/#{item.id}"
  end

  # Submit with the wrong answer
  it 'always shows the best submission and offers no way to select another' do
    enter_quiz_form
    expect(page).to have_css '[role="timer"]'
    expect(page).to have_css '#quiz-state-indicators .x-step', count: 1
    expect(page).to have_text 'What is the Internet?'
    expect(page).to have_text 'The Internet is a global system of interconnected computer networks'
    expect(page).to have_text 'The Internet consists of cookies.'

    # Submit with the wrong answer
    check 'The Internet consists of cookies.'
    click_on 'quiz_submit_button'

    expect(page).to have_text 'An Example Item'
    expect(page).to have_text '0.0 / 3.0'
    expect(page).to have_text '0%'

    click_on 'Retake quiz'

    expect(page).to have_css '[role="timer"]'
    expect(page).to have_css '#quiz-state-indicators .x-step', count: 1
    expect(page).to have_text 'What is the Internet?'
    expect(page).to have_text 'The Internet is a global system of interconnected computer networks'
    expect(page).to have_text 'The Internet consists of cookies.'
  end

  it 'shows the latest submission, not the best-scoring one' do
    enter_quiz_form
    check 'The Internet is a global system of interconnected computer networks'
    click_on 'quiz_submit_button'

    # First attempt: the correct answer.
    expect(page).to have_text '3.0 / 3.0'
    expect(page).to have_text '100%'

    click_on 'Retake quiz'
    check 'The Internet consists of cookies.'
    click_on 'quiz_submit_button'

    # Second attempt: the wrong answer. The latest submission is shown.
    expect(page).to have_text '0.0 / 3.0'
    expect(page).to have_text '0%'

    # Re-entering from the item page shows the latest submission.
    visit "/learn/#{course.course_code}/items/#{item.id}"
    expect(page).to have_text '0.0 / 3.0'
    expect(page).to have_text '0%'
    expect(page).to have_no_select('user_attempts')
  end
end
