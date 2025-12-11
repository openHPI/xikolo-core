# frozen_string_literal: true

module QuizService
class QuizSubmissionSelectableAnswer < QuizSubmissionAnswer # rubocop:disable Layout/IndentationWidth
  belongs_to :quiz_submission_question

  default_scope -> { order(:created_at) }
end
end
