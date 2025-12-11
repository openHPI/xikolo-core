# frozen_string_literal: true

module QuizService
class QuizSubmissionAnswerDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      id:,
        type: "Xikolo::Submission::#{type.delete_prefix('QuizService::')}",
        quiz_submission_question_id:,
        quiz_answer_id:,
        user_answer_text:,
    }.as_json(opts)
  end
end
end
