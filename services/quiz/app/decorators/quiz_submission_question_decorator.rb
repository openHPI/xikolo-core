# frozen_string_literal: true

class QuizSubmissionQuestionDecorator < Draper::Decorator
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
