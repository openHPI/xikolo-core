# frozen_string_literal: true

require 'spec_helper'

describe QuizService::MultipleAnswerQuestion, type: :model do
  let(:multiple_answer_question) { create(:'quiz_service/multiple_answer_question', points: 0) }

  context 'for question without correct answer' do
    let(:answers) { create_list(:'quiz_service/answer', 4, question: multiple_answer_question, correct: false) }
    let(:quiz_submission) { create(:'quiz_service/quiz_submission') }
    let(:quiz_submission_question) { create(:'quiz_service/quiz_submission_question', quiz_submission:, points: 0.0) }

    it 'sets user points to 0 without errors' do
      multiple_answer_question.update_points_from_submission(quiz_submission_question, answers.map(&:id))
      expect(quiz_submission_question.reload.points).to eq 0.0
    end
  end
end
