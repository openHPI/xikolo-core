# frozen_string_literal: true

require 'spec_helper'

describe QuizService::FreeTextQuestionStats, type: :model do
  let(:question_id) { generate(:question_id) }
  let(:question) { QuizService::Question.find(question_id) }

  let(:answer_id_1) { generate(:answer_id) }
  let(:answer_id_2) { generate(:answer_id) }

  before do
    quiz = create(:'quiz_service/quiz')

    question = create(:'quiz_service/free_text_question', id: question_id, quiz:)

    answer1 = create(
      :'quiz_service/answer',
      id: answer_id_1,
      position: 1,
      correct: true,
      text: 'foo',
      question:
    )
    answer2 = create(
      :'quiz_service/answer',
      id: answer_id_2,
      position: 2,
      correct: false,
      text: 'bar',
      question:
    )

    submission1 = create(:'quiz_service/quiz_submission', :submitted, quiz:)
    submission2 = create(:'quiz_service/quiz_submission', :submitted, quiz:)

    qsq1 = create(
      :'quiz_service/quiz_submission_question',
      points: 10,
      quiz_question_id: question.id,
      quiz_submission: submission1
    )
    qsq2 = create(
      :'quiz_service/quiz_submission_question',
      points: 0,
      quiz_question_id: question.id,
      quiz_submission: submission2
    )

    create(
      :'quiz_service/quiz_submission_answer',
      user_answer_text: 'foo',
      quiz_answer_id: answer1.id,
      quiz_submission_question: qsq1
    )
    create(
      :'quiz_service/quiz_submission_answer',
      user_answer_text: 'bar',
      quiz_answer_id: answer2.id,
      quiz_submission_question: qsq2
    )
    create(
      :'quiz_service/quiz_submission_answer',
      user_answer_text: 'bar',
      quiz_answer_id: answer2.id,
      quiz_submission_question: qsq2
    )
  end

  describe '#all' do
    subject(:all) do
      described_class.new(question_id: question.id).all
    end

    it 'returns correct result hash' do
      expect(all).to include(
        id: question_id,
        type: 'QuizService::FreeTextQuestion',
        position: 1,
        max_points: 10,
        avg_points: 5,
        submission_count: 2,
        submission_user_count: 1,
        answers: {
          non_unique_answer_texts: {'bar' => 2},
          unique_answer_count: 1,
        }
      )
    end
  end
end
