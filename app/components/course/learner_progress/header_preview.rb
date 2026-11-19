# frozen_string_literal: true

module Course
  module LearnerProgress
    class HeaderPreview < ViewComponent::Preview
      Progress = Data.define(:completed, :total, :percentage)

      # @!group Progress header

      # @label In progress
      def in_progress
        render ::Course::LearnerProgress::Header.new(
          progress: Progress.new(completed: 20, total: 95, percentage: 21),
          certificates_url: '#certificates'
        )
      end

      # @label Without certificates
      def without_certificates
        render ::Course::LearnerProgress::Header.new(
          progress: Progress.new(completed: 20, total: 95, percentage: 21)
        )
      end
      # @!endgroup
    end
  end
end
