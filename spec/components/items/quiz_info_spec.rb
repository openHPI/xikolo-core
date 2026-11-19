# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Items::QuizInfo, type: :component do
  subject(:component) { described_class.new(quiz) }

  let(:quiz) do
    create(:'quiz_service/quiz', question_pool: false, displayed_question_count: 10)
  end
  let(:question_data) do
    [
      [:'quiz_service/multiple_choice_question', 23, 1],
      [:'quiz_service/multiple_choice_question', 3, 2],
      [:'quiz_service/multiple_answer_question', 4, 3],
    ]
  end

  before do
    question_data.each do |factory, count, points|
      create_list(factory, count, quiz:, points:)
    end
    quiz.update!(question_pool: true)
  end

  it 'shows the fulfilled criteria for a valid question pool' do
    render_inline(component)

    expect(page).to have_text('Exam is ready')
    expect(page).to have_css('.text-success-content', text: '30 / 30 questions in the exam')
    expect(page).to have_css('.text-success-content', text: 'Easy questions: 23 (minimum 3)')
  end

  context 'when questions are missing' do
    let(:question_data) { [] }

    it 'identifies each unmet criterion' do
      render_inline(component)

      expect(page).to have_text('Exam is incomplete')
      expect(page).to have_css('.text-error', text: '0 / 30 questions in the exam')
      expect(page).to have_css('.text-error', text: 'Easy questions: 0 (minimum 3)')
      expect(page).to have_css('.text-error', text: 'Mid questions: 0 (minimum 3)')
      expect(page).to have_css('.text-error', text: 'Hard questions: 0 (minimum 4)')
    end
  end

  context 'when the pool contains an unsupported question type' do
    let(:question_data) do
      [
        [:'quiz_service/free_text_question', 1, 1],
        [:'quiz_service/multiple_choice_question', 22, 1],
        [:'quiz_service/multiple_choice_question', 3, 2],
        [:'quiz_service/multiple_answer_question', 4, 3],
      ]
    end

    it 'identifies the unsupported question' do
      render_inline(component)

      expect(page).to have_text('Exam is incomplete')
      expect(page).to have_css('.text-error', text: '1 question(s) must be single- or multi-select')
    end
  end

  context 'when the pool is disabled' do
    before { quiz.update!(question_pool: false) }

    it 'shows the old quiz summary' do
      render_inline(component)

      expect(page).to have_text('Question(s):')
      expect(page).to have_text('30')
      expect(page).to have_text('Quiz Total Points:')
      expect(page).to have_text('41')
    end
  end
end
