# frozen_string_literal: true

require 'spec_helper'

describe Quiz::CheckBoxes, type: :component do
  subject(:component) { described_class.new question, lang: 'en' }

  let(:question) { Xikolo::Quiz::MultipleAnswerQuestion.new build(:'quiz:question', :multi_select) }

  before do
    # Puke, sorry - no better way to set this up until we use actual database models
    question.instance_variable_set(
      :@answers,
      (1..10).map do |index|
        Xikolo::Quiz::TextAnswer.new(
          id: generate(:uuid),
          question_id: question.id,
          text: index
        )
      end
    )
  end

  it 'renders a checkbox per answer, all of them enabled and unchecked' do
    render_inline(component)

    expect(page).to have_unchecked_field type: 'checkbox', disabled: false, count: 10
  end

  context 'with a submitted user answer' do
    subject(:component) { described_class.new question, lang: 'en', submission:, show_solution: true }

    let(:submission) do
      Xikolo::Submission::QuizSubmissionQuestion.new(
        id: generate(:uuid),
        quiz_submission_id: submission_id,
        quiz_question_id: question.id
      )
    end
    let(:submission_id) { generate(:uuid) }

    before do
      # Same as above - setup will get easier with actual database models
      submission.instance_variable_set(
        :@quiz_submission_answers,
        [
          Xikolo::Submission::QuizSubmissionSelectableAnswer.new(
            id: generate(:uuid),
            quiz_submission_question_id: submission.id,
            quiz_answer_id: question.answers[2].id
          ),
          Xikolo::Submission::QuizSubmissionSelectableAnswer.new(
            id: generate(:uuid),
            quiz_submission_question_id: submission.id,
            quiz_answer_id: question.answers[5].id
          ),
        ]
      )
    end

    it 'renders the checkboxes in disabled state and pre-selects the user-defined answers' do
      render_inline(component)

      expect(page).to have_checked_field type: 'checkbox', disabled: true, count: 2
      expect(page).to have_unchecked_field type: 'checkbox', disabled: true, count: 8

      # Make sure the right checkboxes are checked
      expect(page).to have_field '3', disabled: true, checked: true
      expect(page).to have_field '6', disabled: true, checked: true
    end
  end

  context 'with a snapshot' do
    subject(:component) { described_class.new question, lang: 'en', snapshot: }

    let(:snapshot) do
      Xikolo::Submission::QuizSubmissionSnapshot.new(
        loaded_data: {question.id => [question.answers[4].id, question.answers[8].id]}
      )
    end

    it 'renders the checkboxes editable and pre-filled with the answers stored in the snapshot' do
      render_inline(component)

      expect(page).to have_checked_field type: 'checkbox', disabled: false, count: 2
      expect(page).to have_unchecked_field type: 'checkbox', disabled: false, count: 8

      # Make sure the right checkboxes are checked
      expect(page).to have_field '5', checked: true
      expect(page).to have_field '9', checked: true
    end
  end
end
