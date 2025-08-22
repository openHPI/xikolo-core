# frozen_string_literal: true

class QuizSubmissionFreeTextAnswer < QuizSubmissionAnswer
  belongs_to :quiz_submission_question

  default_scope -> { order(:created_at) }
end
