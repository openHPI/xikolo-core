# frozen_string_literal: true

module LearningEvaluation
  class UpdateCourseProgressWorker
    include Sidekiq::Job

    def perform(course_id, user_id)
      return unless persist_learning_evaluation?

      CourseProgress::Calculate.call(course_id, user_id)
    end

    private

    def persist_learning_evaluation?
      Xikolo.config.persisted_learning_evaluation
    end
  end
end
