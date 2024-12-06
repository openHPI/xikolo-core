# frozen_string_literal: true

module Xikolo::Submission
  class QuizSubmissionAnswer < Acfs::Resource
    service Xikolo::Submission::Client, path: 'quiz_submission_answers'

    attribute :id, :uuid
    attribute :quiz_submission_question_id, :uuid
    attribute :quiz_answer_id, :uuid
  end
end
