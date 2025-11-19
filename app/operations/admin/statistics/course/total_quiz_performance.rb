# frozen_string_literal: true

module Admin
  module Statistics
    module Course
      class TotalQuizPerformance < ApplicationOperation
        include MetricHelpers

        SUPPORTED_TYPES = {
          graded: %w[main bonus],
          selftest: %w[selftest],
        }.freeze

        def initialize(course_id:, type:)
          super()

          @course_id = course_id
          @type = type.to_sym
        end

        def call
          return if course_id.blank?

          quiz_types = SUPPORTED_TYPES[type]
          return unless quiz_types

          quiz_stats = fetch_quiz_statistics(quiz_types)
          return if quiz_stats.blank?

          total_avg_points = 0
          total_max_points = 0

          quiz_stats.each do |stats|
            next unless stats

            if stats['avg_points'] && stats['max_points']
              total_avg_points += stats['avg_points']
              total_max_points += stats['max_points']
            end
          end

          return if total_max_points.zero?

          total_avg_points.fdiv(total_max_points)
        end

        private

        attr_reader :course_id, :type

        def fetch_quiz_statistics(quiz_types)
          promises = []

          Xikolo.paginate(
            course_api.rel(:items).get({
              course_id:,
              was_available: true,
              content_type: 'quiz',
              exercise_type: quiz_types.join(','),
            })
          ) do |quiz|
            promises << quiz_api.rel(:submission_statistic).get({id: quiz['content_id']})
          end

          Restify::Promise.new(promises).value!
        end
      end
    end
  end
end
