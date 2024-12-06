# frozen_string_literal: true

module Xikolo::Submission
  class QuizSubmission < Acfs::Resource
    service Xikolo::Submission::Client, path: 'quiz_submissions'

    attribute :id, :uuid
    attribute :course_id, :uuid
    attribute :quiz_id, :uuid
    attribute :quiz_access_time, :date_time
    attribute :quiz_submission_time, :date_time
    attribute :quiz_version_at, :date_time
    attribute :user_id, :uuid
    attribute :submitted, :boolean
    attribute :points, :float
    attribute :snapshot_id, :uuid
    attribute :fudge_points, :float
    attribute :question_count, :integer
    attribute :vendor_data, :dict

    def enqueue_acfs_request_for_quiz_submissions_questions(&)
      @quiz_submission_questions = Xikolo::Submission::QuizSubmissionQuestion.where(
        quiz_submission_id: id,
        per_page: 250,
        &
      )
    end

    def get_user_submission_question_for(quiz_question_id)
      @quiz_submission_questions.find {|question| question.quiz_question_id == quiz_question_id }
    end

    attr_reader :quiz
  end
end
