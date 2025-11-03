# frozen_string_literal: true

module Steps
  module QuizRecap
    When 'I enter the Quiz Recap page' do
      click_on 'Recap'
    end

    When 'I start a Quiz Recap session' do
      click_on 'Complete set (1 question)'
    end

    When 'I choose the correct answer' do
      check 'The Internet is a global system of interconnected computer networks'
      click_on 'Submit Answer'
      expect(page).to have_content 'Your answer was correct.'
      click_on 'Next Question'
    end

    When 'I choose the wrong answer' do
      check 'The Internet consists of cookies'
      click_on 'Submit Answer'
      expect(page).to have_content 'Your answer was not correct. You have 2 attempts left.'
      click_on 'Next Question'
    end

    When 'I click a review link' do
      review_window = window_opened_by do
        find("[aria-label='Open in new tab']").click
      end

      context.assign :review_window, review_window
    end

    Then 'I should see the instructions' do
      expect(page).to have_content 'Here you can practice your knowledge'
      expect(page).to have_content 'Choose a quiz type'
    end

    Then 'I should see a quiz question' do
      expect(page).to have_content 'What is the Internet?'
      expect(page).to have_content 'The Internet is a global system of interconnected computer networks'
      expect(page).to have_content 'The Internet consists of cookies'
    end

    Then 'I should see the results page' do
      expect(page).to have_content 'Result'
    end

    Then 'I should see the results page with a review link' do
      expect(page).to have_content 'Result'
      find("[aria-label='Open in new tab']")
    end

    Then 'I should see the reference page in a new window' do
      context.with :review_window, :item do |review_window, item|
        within_window(review_window) do
          expect(page).to have_content item['title']
          current_window.close
        end
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::QuizRecap }
