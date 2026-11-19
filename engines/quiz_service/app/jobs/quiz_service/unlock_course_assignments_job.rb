# frozen_string_literal: true

module QuizService
  class UnlockCourseAssignmentsJob < ApplicationJob
    queue_as :default

    def perform(course_id, user_id)
      AttemptsHandler.new(course_id, user_id).unlock_assignments
    end
  end
end
