# frozen_string_literal: true

module CourseService
module LearningEvaluation # rubocop:disable Layout/IndentationWidth
  class UpdateSectionProgressWorker
    include Sidekiq::Job

    def perform(section_id, user_id)
      return unless persist_learning_evaluation?

      SectionProgress::Calculate.call(section_id, user_id)
    end

    private

    def persist_learning_evaluation?
      Xikolo.config.persisted_learning_evaluation
    end
  end
end
end
