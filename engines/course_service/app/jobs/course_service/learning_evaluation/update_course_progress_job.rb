# frozen_string_literal: true

module CourseService
  module LearningEvaluation
    class UpdateCourseProgressJob < ApplicationJob
      queue_as :default

      def perform(course_id, user_id)
        CourseProgress::Calculate.call(course_id, user_id)
      end
    end
  end
end
