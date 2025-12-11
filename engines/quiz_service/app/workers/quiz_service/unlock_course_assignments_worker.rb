# frozen_string_literal: true

module QuizService
class UnlockCourseAssignmentsWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(course_id, user_id)
    AttemptsHandler.new(course_id, user_id).unlock_assignments
  end
end
end
