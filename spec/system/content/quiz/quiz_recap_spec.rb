# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Take a Quiz Recap session', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:quiz) { create(:'quiz_service/quiz') }
  let(:question) do
    create(:'quiz_service/multiple_answer_question',
      quiz:,
      text: 'What is the Internet?',
      points: 3,
      shuffle_answers: false)
  end
  let(:user) { create(:'account_service/user') }

  before do
    create(:'course_service/item', :quiz, section:, content_id: quiz.id, title: 'quiz 1')
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

  it 'Quiz Recap with correct answer' do
    click_on 'Recap'

    expect(page).to have_text 'Here you can practice your knowledge'
    expect(page).to have_text 'Choose a quiz type'

    click_on 'Complete set (1 question)'

    expect(page).to have_text 'What is the Internet?'
    expect(page).to have_text 'The Internet is a global system of interconnected computer networks'
    expect(page).to have_text 'The Internet consists of cookies'

    check 'The Internet is a global system of interconnected computer networks'
    click_on 'Submit Answer'
    expect(page).to have_text 'Your answer was correct.'
    click_on 'Next Question'

    expect(page).to have_text 'Result'
  end

  it 'Quiz Recap with wrong answer' do
    click_on 'Recap'

    click_on 'Complete set (1 question)'

    check 'The Internet consists of cookies'
    click_on 'Submit Answer'
    expect(page).to have_text 'Your answer was not correct. You have 2 attempts left.'
    click_on 'Next Question'

    expect(page).to have_text 'What is the Internet?'
    expect(page).to have_text 'The Internet is a global system of interconnected computer networks'
    expect(page).to have_text 'The Internet consists of cookies'

    check 'The Internet is a global system of interconnected computer networks'
    click_on 'Submit Answer'
    expect(page).to have_text 'Your answer was correct.'
    click_on 'Next Question'

    expect(page).to have_text 'Result'

    review_window = window_opened_by do
      find("[aria-label='Open in new tab']").click
    end

    within_window(review_window) do
      expect(page).to have_text 'quiz 1'
    end
  end
end
