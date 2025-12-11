# frozen_string_literal: true

module QuizService
class AdditionalQuizAttempt < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :additional_quiz_attempts

  validates :user_id, uniqueness: {scope: :quiz_id}

  default_scope -> { order(:created_at) }
end
end
