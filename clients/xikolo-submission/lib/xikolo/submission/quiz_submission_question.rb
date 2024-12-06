# frozen_string_literal: true

module Xikolo::Submission
  class QuizSubmissionQuestion < Acfs::Resource
    service Xikolo::Submission::Client, path: 'quiz_submission_questions'

    attribute :id, :uuid
    attribute :quiz_submission_id, :uuid
    attribute :quiz_question_id, :uuid
    attribute :points, :float

    def enqueue_acfs_request_for_quiz_submissions_answers(&)
      @quiz_submission_answers = Xikolo::Submission::QuizSubmissionAnswer.where(
        quiz_submission_question_id: id,
        per_page: 500,
        &
      )
    end

    attr_reader :quiz_submission_answers
  end
end
