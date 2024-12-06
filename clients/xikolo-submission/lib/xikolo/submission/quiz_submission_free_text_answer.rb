# frozen_string_literal: true

module Xikolo::Submission
  class QuizSubmissionFreeTextAnswer < Xikolo::Submission::QuizSubmissionAnswer
    service Xikolo::Submission::Client, path: 'quiz_submission_free_text_answers'

    attribute :user_answer_text, :string
  end
end
