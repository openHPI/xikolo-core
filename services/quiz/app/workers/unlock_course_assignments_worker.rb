# frozen_string_literal: true

class UnlockCourseAssignmentsWorker
  include Sidekiq::Job

  def perform(course_id, user_id)
    AttemptsHandler.new(course_id, user_id).unlock_assignments
  end
end
