# frozen_string_literal: true

class QuizSubmissionAnswer < ApplicationRecord
  self.table_name = :quiz_submission_answers

  belongs_to :quiz_submission_question

  default_scope -> { order(:created_at) }
end
