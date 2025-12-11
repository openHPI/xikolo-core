# frozen_string_literal: true

module QuizService
module UserQuizAttemptsHelper # rubocop:disable Layout/IndentationWidth
  def grant_additional_attempt(user_id, quiz_id, add_attempts = 1)
    additional_attempts = AdditionalQuizAttempt.find_or_initialize_by(user_id:, quiz_id:)
    current_count = additional_attempts.count
    current_count = 0 if current_count.nil? # new objects are initialized with nil
    add_attempts = current_count + 1 if add_attempts.nil?
    additional_attempts.count = Integer(add_attempts)
    additional_attempts.save!
  end
end
end
