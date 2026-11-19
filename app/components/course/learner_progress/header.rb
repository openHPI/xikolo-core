# frozen_string_literal: true

module Course
  module LearnerProgress
    # The learner's completed content in a course, with a link to their
    # certificates. Shows the same numbers as the course navigation progress bar.
    class Header < ApplicationComponent
      # @param progress [Course::CompletedItemsProgress] anything responding to
      #   `completed`, `total` and `percentage`
      # @param certificates_url [String, nil] the certificates link is hidden without a URL
      def initialize(progress:, certificates_url: nil)
        @progress = progress
        @certificates_url = certificates_url
      end

      private

      def percentage
        @progress.percentage
      end

      def formatted_percentage
        helpers.number_to_percentage(percentage, precision: 0)
      end

      def count
        t(:'course.progress.header.count', completed: @progress.completed, total: @progress.total)
      end
    end
  end
end
