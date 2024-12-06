# frozen_string_literal: true

class QuizSubmissionAnswerDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
        type: "Xikolo::Submission::#{type}",
        quiz_submission_question_id:,
        quiz_answer_id:,
        user_answer_text:,
    }.as_json(opts)
  end
end
