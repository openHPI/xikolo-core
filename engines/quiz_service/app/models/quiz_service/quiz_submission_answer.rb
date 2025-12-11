# frozen_string_literal: true

module QuizService
class QuizSubmissionAnswer < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :quiz_submission_answers

  belongs_to :quiz_submission_question

  default_scope -> { order(:created_at) }
end
end
