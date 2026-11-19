# frozen_string_literal: true

module CourseService
  module LearningEvaluation
    class UpdateSectionProgressJob < ApplicationJob
      queue_as :default

      def perform(section_id, user_id)
        SectionProgress::Calculate.call(section_id, user_id)
      end
    end
  end
end
