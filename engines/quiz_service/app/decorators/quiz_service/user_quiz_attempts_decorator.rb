# frozen_string_literal: true

module QuizService
class UserQuizAttemptsDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      user_id:,
      quiz_id:,
      additional_attempts: additional_attempts || 0,
      attempts:,
    }.as_json(opts)
  end
end
end
