# frozen_string_literal: true

class QuizSubmissionAnswer < ApplicationRecord
  belongs_to :quiz_submission_question

  default_scope -> { order('created_at ASC') }
end
