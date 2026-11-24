# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Take a quiz', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user:)
    enroll_in(course)
  end

  def displayed_pool_questions
    all('#quiz_form [data-testid="quiz-question"]', visible: :all).pluck(:id)
  end

  def choose_pool_answers(kind)
    question_count = displayed_pool_questions.size
    all('#quiz_form [data-testid="accordion-section"]', count: question_count).each do |section|
      summary = section.find('summary')
      # This is a state check, not a wait for a closed section to open itself.
      summary.click unless section.matches_css?('[open]', wait: 0)
      within(section) do
        find(:label, text: /^#{Regexp.escape(kind)} for Pool question \[\d+\]$/)
          .find(:radio_button).choose
      end
    end

    expect(page).to have_css('#quiz-state-indicators .x-step[data-answered]', count: question_count)
  end

  describe 'selftest quiz' do
    let(:quiz) { create(:'quiz_service/quiz', allowed_attempts: 2) }
    let(:question) do
      create(:'quiz_service/multiple_answer_question',
        quiz:,
        text: 'What is the Internet?',
        points: 3,
        shuffle_answers: false)
    end

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
    end

    it 'takes a selftest' do
      item = create(:'course_service/item', :quiz,
        section:, content: quiz, title: 'An Example Item',
        max_dpoints: 30)

      within('[data-testid="course-details-card"]') do
        click_on 'Continue course'
      end

      expect(page).to have_current_path(%r{/quiz_submission/new})

      expect(page).to have_css '[role="timer"]'
      expect(page).to have_css '#quiz-state-indicators .x-step'
      expect(page).to have_text 'What is the Internet?'
      expect(page).to have_text 'The Internet is a global system of interconnected computer networks'
      expect(page).to have_text 'The Internet consists of cookies.'

      check 'The Internet is a global system of interconnected computer networks'
      expect(page).to have_text '1 of 1 questions answered'
      click_on 'quiz_submit_button'

      expect(page).to have_text 'Correct answer'
      expect(page).to have_text '3.0 / 3.0'
      expect(page).to have_text '100%'
      expect(page).to have_text 'Retake quiz'

      click_on 'Retake quiz'

      expect(page).to have_css '[role="timer"]'
      expect(page).to have_css '#quiz-state-indicators .x-step'
      expect(page).to have_text 'What is the Internet?'

      check 'The Internet consists of cookies.'
      click_on 'quiz_submit_button'

      expect(page).to have_text '0.0 / 3.0'
      expect(page).to have_text '0%'

      visit "/learn/#{course.course_code}/items/#{item.id}"

      expect(page).to have_text '0.0 / 3.0'
      expect(page).to have_text '0%'
    end

    it 'navigates questions through the accordion footer and quiz steps' do
      other_question = create(:'quiz_service/multiple_answer_question', quiz:, text: 'Second question')
      create(:'quiz_service/text_answer', question: other_question, text: 'Second answer')
      create(:'course_service/item', :quiz,
        section:, content: quiz, title: 'An Example Item', max_dpoints: 30)

      within('[data-testid="course-details-card"]') { click_on 'Continue course' }

      check 'The Internet consists of cookies.'
      expect(page).to have_css('summary [data-quiz-steps-answered-badge]', text: 'Answered')
      expect(page).to have_text '1 of 2 questions answered'

      click_on 'Next question'
      expect(page).to have_text 'Second question'
      expect(page).to have_no_text 'What is the Internet?'
      expect(page).to have_css('summary:focus', text: 'Question 2')

      click_on 'Previous question'
      expect(page).to have_text 'What is the Internet?'
      expect(page).to have_no_text 'Second question'

      find("#quiz-state-indicators a[href='##{other_question.id}']").click
      expect(page).to have_text 'Second question'
      expect(page).to have_no_text 'What is the Internet?'
      expect(page).to have_css('details[open]', count: 1)

      find("summary[aria-controls='accordion-section-#{other_question.id}']").click
      expect(page).to have_no_text 'Second question'
      find("summary[aria-controls='accordion-section-#{other_question.id}']").send_keys(:enter)
      expect(page).to have_text 'Second question'
    end

    it 'does not allow access when deadline has passed' do
      item = create(:'course_service/item', :quiz,
        section:, content: quiz, title: 'An Example Item',
        max_dpoints: 30,
        submission_deadline: 2.days.ago)

      visit "/learn/#{course.course_code}/items/#{item.id}"

      expect(page).to have_text 'You cannot enter any new submissions, because the submission deadline has already passed.'
      expect(page).to have_no_text 'Retake quiz'
    end

    it 'shows results when deadline has passed and results are published' do
      item = create(:'course_service/item', :quiz,
        section:, content: quiz, title: 'An Example Item',
        max_dpoints: 30)

      within('[data-testid="course-details-card"]') do
        click_on 'Continue course'
      end

      check 'The Internet consists of cookies.'
      click_on 'quiz_submit_button'

      expect(page).to have_text '0.0 / 3.0'
      expect(page).to have_text '0%'

      item.update!(submission_deadline: 2.days.ago, submission_publishing_date: 1.day.ago)

      visit "/learn/#{course.course_code}/items/#{item.id}"

      expect(page).to have_text '0.0 / 3.0'
      expect(page).to have_text '0%'
    end
  end

  describe 'main quiz' do
    let(:quiz) { create(:'quiz_service/quiz', allowed_attempts: 2) }
    let(:question) do
      create(:'quiz_service/multiple_answer_question',
        quiz:,
        text: 'What is the Internet?',
        points: 3,
        shuffle_answers: false)
    end

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
    end

    it 'takes a main quiz with unlimited attempts' do
      quiz.update!(unlimited_attempts: true)

      item = create(:'course_service/item', :homework,
        section:, content: quiz, title: 'An Example Item',
        max_dpoints: 30)

      within('[data-testid="course-details-card"]') do
        click_on 'Continue course'
      end

      expect(page).to have_text 'An Example Item'
      expect(page).to have_text 'Quiz Instruction'
      expect(page).to have_text 'This is a graded assignment/ exam'
      expect(page).to have_no_text 'Results'

      click_on 'Start quiz now'
      click_on 'Yes, sure'

      expect(page).to have_css '[role="timer"]'
      expect(page).to have_css '#quiz-state-indicators .x-step'
      expect(page).to have_text 'What is the Internet?'
      expect(page).to have_text 'The Internet is a global system of interconnected computer networks'
      expect(page).to have_text 'The Internet consists of cookies.'

      check 'The Internet is a global system of interconnected computer networks'
      click_on 'quiz_submit_button'

      expect(page).to have_text('Your quiz solution has been submitted successfully.')

      expect(page).to have_text 'An Example Item'
      expect(page).to have_text 'Quiz Instruction'
      expect(page).to have_text 'This is a graded assignment/ exam'
      expect(page).to have_text 'Results'
      expect(page).to have_text 'Retake quiz'

      within('nav[aria-label="Course actions"]') { click_on 'Retake quiz' }

      expect(page).to have_css '[role="timer"]'
      expect(page).to have_css '#quiz-state-indicators .x-step'
      expect(page).to have_text 'What is the Internet?'

      check 'The Internet is a global system of interconnected computer networks'
      click_on 'quiz_submit_button'

      expect(page).to have_text('Your quiz solution has been submitted successfully.')

      expect(page).to have_text 'An Example Item'
      expect(page).to have_text 'Quiz Instruction'
      expect(page).to have_text 'Results'
      expect(page).to have_text 'Retake quiz'

      visit "/learn/#{course.course_code}/items/#{item.id}"

      expect(page).to have_text 'An Example Item'
      expect(page).to have_text 'Quiz Instruction'
      expect(page).to have_text 'Results'
      expect(page).to have_text 'Retake quiz'

      click_on 'Results'

      expect(page).to have_text 'Correct answer'
      expect(page).to have_text '3.0 / 3.0'
      expect(page).to have_text '100%'
    end

    it 'takes a main quiz without deadline' do
      item = create(:'course_service/item', :homework,
        section:, content: quiz, title: 'An Example Item',
        max_dpoints: 30)

      within('[data-testid="course-details-card"]') do
        click_on 'Continue course'
      end

      expect(page).to have_text 'An Example Item'
      expect(page).to have_text 'Quiz Instruction'
      expect(page).to have_text 'This is a graded assignment/ exam'

      click_on 'Start quiz now'
      click_on 'Yes, sure'

      expect(page).to have_css '[role="timer"]'
      expect(page).to have_css '#quiz-state-indicators .x-step'
      expect(page).to have_text 'What is the Internet?'

      check 'The Internet is a global system of interconnected computer networks'
      click_on 'quiz_submit_button'

      expect(page).to have_text('Your quiz solution has been submitted successfully.')

      expect(page).to have_text 'An Example Item'
      expect(page).to have_text 'Quiz Instruction'
      expect(page).to have_text 'Results'
      expect(page).to have_text 'Retake quiz'

      within('nav[aria-label="Course actions"]') { click_on 'Retake quiz' }

      expect(page).to have_css '[role="timer"]'
      expect(page).to have_css '#quiz-state-indicators .x-step'
      expect(page).to have_text 'What is the Internet?'

      check 'The Internet consists of cookies.'
      click_on 'quiz_submit_button'

      expect(page).to have_text('Your quiz solution has been submitted successfully.')

      expect(page).to have_text '0.0 / 3.0'
      expect(page).to have_text '0%'

      visit "/learn/#{course.course_code}/items/#{item.id}"

      expect(page).to have_text '3.0 / 3.0'
      expect(page).to have_text '100%'
    end

    it 'allows users to make empty submissions' do
      create(:'course_service/item', :homework,
        section:, content: quiz, title: 'An Example Item',
        max_dpoints: 30)

      within('[data-testid="course-details-card"]') do
        click_on 'Continue course'
      end

      click_on 'Start quiz now'
      click_on 'Yes, sure'
      click_on 'quiz_submit_button'

      expect(page).to have_text 'You have not answered all of the questions.'

      # Cover the case where the user clicks "Cancel" on the confirmation dialog
      click_on 'Cancel'

      click_on 'quiz_submit_button'

      # Cover the case where the user clicks "Yes, sure" on the confirmation dialog
      click_on 'Submit answers'

      expect(page).to have_text 'No answers were submitted for your quiz solution.'
    end

    it 'confirms a retake from the bottom bar before results are published' do
      item = create(:'course_service/item', :homework,
        section:, content: quiz, title: 'An Example Item',
        submission_deadline: 2.days.from_now, submission_publishing_date: 3.days.from_now)

      visit course_item_path(course.course_code, item.id)
      click_on 'Start quiz now'
      click_on 'Yes, sure'
      check 'The Internet is a global system of interconnected computer networks'
      click_on 'Send my final answers'

      expect(page).to have_text 'Your quiz solution has been submitted successfully.'
      within('nav[aria-label="Course actions"]') { click_on 'Retake quiz' }
      expect(page).to have_text I18n.t('items.quiz.confirm_start_quiz')
      click_on 'Yes, sure'

      expect(page).to have_css '[role="timer"]'
      expect(page).to have_text 'What is the Internet?'
    end

    it 'takes a main quiz with deadline not passed' do
      item = create(:'course_service/item', :homework,
        section:, content: quiz, title: 'An Example Item',
        max_dpoints: 30,
        submission_deadline: 2.days.from_now)

      within('[data-testid="course-details-card"]') do
        click_on 'Continue course'
      end

      expect(page).to have_text 'An Example Item'
      expect(page).to have_text 'Quiz Instruction'
      expect(page).to have_text 'This is a graded assignment/ exam'

      within('nav[aria-label="Course actions"]') { click_on 'Start quiz now' }
      click_on 'Yes, sure'

      expect(page).to have_css '[role="timer"]'
      expect(page).to have_css '#quiz-state-indicators .x-step'
      expect(page).to have_text 'What is the Internet?'

      check 'The Internet is a global system of interconnected computer networks'
      click_on 'quiz_submit_button'

      expect(page).to have_text('Your quiz solution has been submitted successfully.')

      expect(page).to have_text 'An Example Item'
      expect(page).to have_text 'Quiz Instruction'
      expect(page).to have_text 'Results'
      expect(page).to have_text 'Retake quiz'

      within('nav[aria-label="Course actions"]') do
        expect(page).to have_link('Retake quiz')
        click_on 'Results'
      end
      expect(page).to have_text '3.0 / 3.0'

      visit course_item_path(course.course_code, item.id)
      within('nav[aria-label="Course actions"]') { click_on 'Retake quiz' }

      expect(page).to have_css '[role="timer"]'
      expect(page).to have_css '#quiz-state-indicators .x-step'
      expect(page).to have_text 'What is the Internet?'

      check 'The Internet consists of cookies.'
      click_on 'quiz_submit_button'

      expect(page).to have_text('Your quiz solution has been submitted successfully.')

      expect(page).to have_text '0.0 / 3.0'
      expect(page).to have_text '0%'

      visit "/learn/#{course.course_code}/items/#{item.id}"

      expect(page).to have_text '3.0 / 3.0'
      expect(page).to have_text '100%'
    end

    it 'does not allow access when deadline has passed' do
      create(:'course_service/item', :homework,
        section:, content: quiz, title: 'An Example Item',
        max_dpoints: 30,
        submission_deadline: 2.days.ago)

      within('[data-testid="course-details-card"]') do
        click_on 'Continue course'
      end

      expect(page).to have_text 'You cannot enter any new submissions, because the submission deadline has already passed.'
      expect(page).to have_no_text 'Retake quiz'
    end

    it 'shows results when deadline has passed and results are published' do
      item = create(:'course_service/item', :homework,
        section:, content: quiz, title: 'An Example Item',
        max_dpoints: 30)

      within('[data-testid="course-details-card"]') do
        click_on 'Continue course'
      end

      click_on 'Start quiz now'
      click_on 'Yes, sure'

      check 'The Internet consists of cookies.'
      click_on 'quiz_submit_button'

      expect(page).to have_text('Your quiz solution has been submitted successfully.')

      item.update!(submission_deadline: 2.days.ago, submission_publishing_date: 1.day.ago)

      visit "/learn/#{course.course_code}/items/#{item.id}"

      expect(page).to have_text '0.0 / 3.0'
      expect(page).to have_text '0%'
    end
  end

  describe 'question pool quiz' do
    before do
      page.driver.browser.execute_cdp('Emulation.setEmulatedMedia',
        features: [{name: 'prefers-reduced-motion', value: 'reduce'}])
    end

    after do
      page.driver.browser.execute_cdp('Emulation.setEmulatedMedia', features: [])
    end

    context 'with already at least 75% completed course progress' do
      before do
        quiz = create(:'quiz_service/quiz', :with_question_pool, allowed_attempts: 2)
        create(:'course_service/item', :homework,
          section:, content: quiz, exercise_type: 'exam', title: 'Question pool exam')
        create(:'course_service/course_progress', course:, user_id: user.id, visits: 10, main_dpoints: 100)
      end

      it 'takes two attempts with the same questions and different scores' do
        within('[data-testid="course-details-card"]') do
          click_on 'Continue course'
        end

        within('nav[aria-label="Course actions"]') { click_on 'Start exam now' }
        click_on 'Start exam', exact: true

        first_attempt_questions = displayed_pool_questions

        choose_pool_answers 'Incorrect answer'
        click_on 'quiz_submit_button'

        expect(page).to have_text('Your quiz solution has been submitted successfully.')

        click_on 'Results'

        expect(page).to have_text('0.0 of 21.0 points achieved')
        expect(page).to have_text('You did not pass the exam yet. You need to achieve at least 70 % of the total points to pass the exam.')

        click_on 'Retake quiz'

        second_attempt_questions = displayed_pool_questions
        expect(second_attempt_questions).to eq(first_attempt_questions)

        choose_pool_answers 'Correct answer'
        click_on 'quiz_submit_button'

        expect(page).to have_text('Your quiz solution has been submitted successfully.')
        expect(page).to have_text('21.0 of 21.0 points achieved')
        expect(page).to have_text('Congratulations, you have passed the exam.')
        expect(page).to have_no_link('Retake quiz')
      end
    end

    context 'with less than 75% completed course progress' do
      before do
        quiz = create(:'quiz_service/quiz', :with_question_pool, allowed_attempts: 2)
        create(:'course_service/item', :homework,
          section:, content: quiz, exercise_type: 'exam', title: 'Question pool exam')
        create(:'course_service/course_progress', course:, user_id: user.id, visits_percentage_fpoints: 74)
      end

      it 'does not allow to take the quiz' do
        within('[data-testid="course-details-card"]') do
          click_on 'Continue course'
        end

        expect(page).to have_text('This exam unlocks once you have completed at least 75% of the course.')
        expect(page).to have_no_link('Start quiz now')
        expect(page).to have_no_button('Start exam now')
      end
    end
  end
end
