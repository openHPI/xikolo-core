# frozen_string_literal: true

module Maintenance
  class RecalculateProgressTask < MaintenanceTasks::Task
    attribute :from, :date
    attribute :to, :date
    validates :from, :to, presence: true

    def collection
      CourseService::Visit.includes(:item).where(created_at: from..to)
    end

    def process(element)
      CourseService::LearningEvaluation::UpdateSectionProgressJob.perform_now(
        element.item.section_id,
        element.user_id
      )
    end
  end
end
