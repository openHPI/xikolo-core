# frozen_string_literal: true

module Xikolo::Submission
  class UserQuizAttempts < Acfs::SingletonResource
    service Xikolo::Submission::Client, path: 'user_quiz_attempts'

    attribute :user_id, :uuid
    attribute :quiz_id, :uuid
    attribute :additional_attempts, :integer
    attribute :attempts, :integer

    def remaining_attempts_for_quiz(quiz)
      quiz.current_allowed_attempts + additional_attempts - attempts
    end

    def attempts_for_quiz_remaining?(quiz)
      remaining_attempts_for_quiz(quiz).positive?
    end
  end
end
