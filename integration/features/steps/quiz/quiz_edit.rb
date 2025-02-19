# frozen_string_literal: true

module Steps
  module QuizEdit
    def update_answer(answer)
      Server[:quiz].api.rel(:answer).patch(
        {correct: true},
        {id: answer.id}
      ).value!
    end

    Given 'multiple quiz question answers are correct' do
      context.with :answer_2 do |answer|
        update_answer answer
      end
    end

    When 'I open the questions tab' do
      click_on 'Questions'
      expect(page).to have_content 'Question type'
    end

    When 'I edit the first question' do
      within '.quiz-question-editor__header' do
        find("[aria-label='More actions']").click
      end

      within "[data-behaviour='menu-dropdown']" do
        click_on 'Edit question'
      end
    end

    When 'I add a new answer' do
      click_on('Add answer')
      fill_markdown_editor('Answer text', with: 'Newly added answer')
      click_on('Create Answer')
    end

    When 'I delete the first question' do
      context.with :quiz_question do |question|
        within "[data-id='#{question.id}'] .quiz-question-editor__header" do
          find("[aria-label='More actions']").click
          within "[data-behaviour='menu-dropdown']" do
            click_on 'Delete question'
          end
        end
      end
    end

    When 'I edit the first answer' do
      context.with :answer_1 do |answer|
        within "[data-id='#{answer.id}']" do
          find("[aria-label='More actions']").click
          click_on('Edit')
        end
      end
    end

    When 'I delete the first answer' do
      context.with :answer_1 do |answer|
        within "[data-id='#{answer.id}']" do
          find("[aria-label='More actions']").click
          click_on('Delete')
        end
      end
    end

    When 'I change the question type' do
      select 'Single Select', from: 'Type'
      click_on 'Submit Question'
    end

    When 'I change the answer text' do
      fill_markdown_editor('Answer text', with: 'New answer text')
      click_on('Update Answer')
    end

    When 'I confirm the deletion warning' do
      expect(page).to have_content 'Are you sure you want to delete this question?'
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I confirm the answer deletion warning' do
      expect(page).to have_content 'Are you sure you want to delete this answer?'
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    Then 'the question has been deleted successfully' do
      expect(page).to have_content 'Question(s): 0'
    end

    Then 'the answer has been deleted successfully' do
      context.with :answer_1 do |answer|
        expect(page).not_to have_content answer.text
      end
    end

    Then 'the new question type should be applied' do
      send :'When I open the questions tab'

      within '.quiz-question-editor' do
        expect(page).to have_content('Question 1')
        expect(page).to have_content('Single Select Question')
      end
    end

    Then 'the new answer text should be applied' do
      expect(page).to have_content 'New answer text'
    end

    Then 'the new answer should be visible' do
      expect(page).to have_content 'Newly added answer'
    end

    Then 'I should be notified that the question type needs to be reviewed' do
      expect(page).to have_content <<~TEXT.strip
        Single Select Questions should only have 1 correct \
        answer! Please review the question.
      TEXT
    end
  end
end

Gurke.configure {|c| c.include Steps::QuizEdit }
