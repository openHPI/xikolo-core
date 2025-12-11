# frozen_string_literal: true

require 'spec_helper'

describe QuizService::EssayQuestionStats, type: :model do
  let(:question_id) { generate(:question_id) }
  let(:question) { QuizService::Question.find(question_id) }

  before do
    quiz = create(:'quiz_service/quiz')

    question = create(:'quiz_service/essay_question', id: question_id, quiz:)

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
      user_answer_text: 'foobar',
      quiz_submission_question: qsq1
    )
    create(
      :'quiz_service/quiz_submission_answer',
      user_answer_text: 'hello world',
      quiz_submission_question: qsq1
    )
    create(
      :'quiz_service/quiz_submission_answer',
      user_answer_text: 'hi there',
      quiz_submission_question: qsq2
    )
    create(
      :'quiz_service/quiz_submission_answer',
      user_answer_text: 'what is this',
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
        type: 'QuizService::EssayQuestion',
        position: 1,
        max_points: 10,
        avg_points: 5,
        submission_count: 2,
        submission_user_count: 1,
        answers: {
          avg_length: 9.25,
        }
      )
    end
  end
end
