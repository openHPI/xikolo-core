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
    end

    When 'I edit the first question' do
      click_on 'Actions'
      within '.dropdown-menu' do
        click_on 'Edit question'
      end
    end

    When 'I add a new answer' do
      click_on('Add answer')
      fill_markdown_editor('Answer text', with: 'Newly added answer')
      click_on('Create Answer')
    end

    When 'I delete the first question' do
      click_on 'Actions'
      within '.dropdown-menu' do
        click_on 'Delete question'
      end
    end

    When 'I edit the first answer' do
      first("[aria-label='Edit']").click
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

    Then 'the question has been deleted successfully' do
      expect(page).to have_content 'Question(s): 0'
    end

    Then 'the new question type should be applied' do
      send :'When I open the questions tab'
      expect(page).to have_content 'Question 1: ( Single Select Question )'
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
