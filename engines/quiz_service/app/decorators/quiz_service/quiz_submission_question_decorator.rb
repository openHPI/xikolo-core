# frozen_string_literal: true

module QuizService
class QuizSubmissionQuestionDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      id:,
        quiz_submission_id:,
        quiz_question_id:,
        points:,
    }.as_json(opts)
  end
end
end
