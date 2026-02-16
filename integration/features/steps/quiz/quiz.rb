# frozen_string_literal: true

module Steps
  module Quiz
    Then 'I should see a countdown of the remaining time' do
      expect(page).to have_selector '[role="timer"]'
    end

    Given 'I select the item for watching' do
      select_item_to_watch
    end

    Given 'I submitted a main quiz with wrong answer' do
      send :'When I start the quiz'
      send :'Then I confirm the main quiz pop-up'
      send :'Then I see the running quiz'
      send :'When I select the wrong answer'
      send :'When I submit the quiz'
    end

    Given 'I submitted the selftest once' do
      send :'Given I am on the item page'
      send :'Then I see the running quiz'
      send :'When I select the wrong answer'
      send :'When I submit the quiz'
    end

    When 'I start the quiz' do
      click_on 'Start quiz now'
    end

    Then 'I confirm the main quiz pop-up' do
      click_on 'Yes, sure'
    end

    When 'I start the quiz again' do
      click_on 'Retake quiz'
      send :'Then I see the running quiz'
    end

    When 'I select the correct answer' do
      check('The Internet is a global system of interconnected computer networks')
    end

    When 'I select the wrong answer' do
      check('The Internet consists of cookies.')
    end

    When 'I select an answer' do
      send :'When I select the correct answer'
    end

    When 'I submit the quiz' do
      click_on 'quiz_submit_button'
    end

    When 'I submit the survey' do
      send :'When I submit the quiz'
    end

    When 'I retake the quiz' do
      click_on 'Retake quiz'
      send :'Then I see the running quiz'
      send :'When I select the correct answer'
      send :'When I submit the quiz'
    end

    When 'I retake the quiz selecting the wrong answer' do
      click_on 'Retake quiz'
      send :'Then I see the running quiz'
      send :'When I select the wrong answer'
      send :'When I submit the quiz'
    end

    When 'I want to see my submissions' do
      click_on 'Results'
    end

    When 'I choose the first submission' do
      option = find_field('user_attempts').first('option')
      page.select option.text, from: 'user_attempts'
    end

    Then 'I see the quiz intro page' do
      send :'Then I see the quiz intro page information'
      expect(page).to_not have_content 'Results'
    end

    Then 'I see the quiz intro page with results' do
      send :'Then I see the quiz intro page information'
      expect(page).to have_content 'Results'
    end

    Then 'I see the split navigation on the quiz intro page' do
      send :'Then I see the quiz intro page information'
      expect(page).to have_content 'Results'
      expect(page).to have_content 'Retake quiz'
    end

    Then 'I see the quiz intro page information' do
      expect(page).to have_content 'An Example Item'
      expect(page).to have_content 'Quiz Instruction:'
      expect(page).to have_content 'This is a graded assignment/ exam'
    end

    Then 'I see the running quiz' do
      send :'Then I should see a countdown of the remaining time'
      # send:'Then I should see how many attempts I have left'
      send :'Then I should see when my answers have been auto-saved the last time'
      send :'Then I should see a list of the questions'
      send :'Then I should see the questions'
      send :'Then I should see the answers'
    end

    Then 'I should see when my answers have been auto-saved the last time' do
      expect(page).to have_content 'Last saved:'
    end

    Then 'I should see an overview of my submissions' do
      expect(page).to have_content 'Your submissions:'
    end

    Then 'I can choose one of my submissions' do
      expect(page).to have_content 'Choose submission:'
      expect(page).to have_select('user_attempts')
    end

    Then 'I should see a list of the questions' do
      expect(page).to have_selector '.answer-state-indicator'
      within first('.answer-state-indicator') do
        expect(page).to have_content '1'
      end
    end

    Then 'I should see the questions' do
      expect(page).to have_content 'What is the Internet?'
    end

    Then 'I should see the answers' do
      expect(page).to have_content 'The Internet is a global system of interconnected computer networks'
      expect(page).to have_content 'The Internet consists of cookies.'
    end

    Then 'I should see the assessment of my submission' do
      expect(page).to have_content 'Correct!'
      send :'Then I see the result of the submission with the correct answer'
      expect(page).to have_content 'Retake quiz'
    end

    Then 'I see the result of the submission with the correct answer' do
      expect(page).to have_content '3.0 / 3.0'
      expect(page).to have_content '100%'
    end

    Then 'I see the result of the submission with the wrong answer' do
      expect(page).to have_content '0.0 / 3.0'
      expect(page).to have_content '0%'
    end

    Then 'I should see the result of the first submission' do
      send :'Then I see the result of the submission with the wrong answer'
    end

    Then 'I should see the survey confirmation' do
      expect(page).to have_content <<~TEXT.strip
        Thank you for your participation in this survey. Your feedback is \
        valuable to improve the learning experience!
      TEXT
    end

    Then 'I should not be able to access the item' do
      expect(page).to have_content <<~TEXT.strip
        You cannot enter any new submissions, because the submission \
        deadline has already passed.
      TEXT
      expect(page).to_not have_content 'Retake quiz'
    end

    Then 'I see the publishing info' do
      expect(page).to have_selector '#quiz_properties'
      expect(page).to_not have_content 'Retake quiz'
    end
  end
end

Gurke.configure {|c| c.include Steps::Quiz }
