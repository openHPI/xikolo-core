# frozen_string_literal: true

require 'spec_helper'

describe Quiz::Dropdown, type: :component do
  subject(:component) { described_class.new question }

  let(:question) { Xikolo::Quiz::MultipleChoiceQuestion.new build(:'quiz:question') }

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

  it 'renders a dropdown with one option per answer, plus a pre-selected default option' do
    render_inline(component)

    expect(page).to have_css 'select > option', count: 11
    expect(page).to have_css 'select > option[disabled]', count: 1
    expect(page).to have_css 'select > option[selected]', count: 1

    expect(page).to have_css 'select > option[disabled][selected]', exact_text: 'Please select'
  end

  context 'with a submitted user answer' do
    subject(:component) { described_class.new question, submission: }

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
        ]
      )
    end

    it 'renders the dropdown and pre-selects the user-defined answer' do
      render_inline(component)

      expect(page).to have_css 'select > option', count: 11
      expect(page).to have_css 'select > option[disabled]', count: 1
      expect(page).to have_css 'select > option[selected]', count: 1

      # Make sure the selected match from above is not also the disabled one
      expect(page).to have_no_selector 'select > option[disabled][selected]'

      expect(page).to have_css 'select > option[selected]', exact_text: '3'
    end
  end

  context 'with a snapshot' do
    subject(:component) { described_class.new question, snapshot: }

    let(:snapshot) do
      Xikolo::Submission::QuizSubmissionSnapshot.new(
        loaded_data: {question.id => question.answers[4].id}
      )
    end

    it 'renders the dropdown and pre-selects the answer stored in the snapshot' do
      render_inline(component)

      expect(page).to have_css 'select > option', count: 11
      expect(page).to have_css 'select > option[disabled]', count: 1
      expect(page).to have_css 'select > option[selected]', count: 1

      # Make sure the selected match from above is not also the disabled one
      expect(page).to have_no_selector 'select > option[disabled][selected]'

      expect(page).to have_css 'select > option[selected]', exact_text: '5'
    end
  end
end
