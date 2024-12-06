# frozen_string_literal: true

class UserQuizAttempts
  extend ActiveModel::Naming

  attr_reader :user_id, :quiz_id, :additional_attempts, :attempts

  def initialize(user_and_quiz_hash)
    @user_id = user_and_quiz_hash[:user_id]
    @quiz_id = user_and_quiz_hash[:quiz_id]

    additional_attempts_entry = AdditionalQuizAttempt.find_by(user_id:, quiz_id:)
    @additional_attempts = additional_attempts_entry.nil? ? 0 : additional_attempts_entry.count

    @attempts = QuizSubmission.where(user_id:, quiz_id:).where_submitted(true).count
  end

  def decorate
    UserQuizAttemptsDecorator.new self
  end
end
