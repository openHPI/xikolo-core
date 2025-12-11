# frozen_string_literal: true

module Admin
  module Statistics
    class HistoricData < ApplicationOperation
      include MetricHelpers

      def initialize(course_id: nil)
        super()

        @course_id = course_id
      end

      def call
        data = fetch_historic_data(@course_id)
        return [] if data.blank?

        # Sort chronologically, then only keep rows where the total enrollments changed
        sorted = data.select do |entry|
          entry[:timestamp].present? && entry[:total_enrollments].present?
        end.sort_by do |entry|
          entry[:timestamp]
        end

        last_total = nil

        sorted.filter_map do |entry|
          total = entry[:total_enrollments]
          next if total == last_total

          last_total = total

          {
            'date' => I18n.l(entry[:timestamp], format: :short),
            'total_enrollments' => total,
          }
        end
      end

      private

      def fetch_historic_data(course_id)
        course = course_api.rel(:course).get({id: course_id}).value!

        end_date =
          if course['end_date'].blank? || DateTime.parse(course['end_date']).future?
            DateTime.now
          else # end_date is in the past
            DateTime.parse(course['end_date']) + 12.weeks
          end

        lanalytics = lanalytics_api
        return [] unless lanalytics

        course_statistics = begin
          lanalytics.rel(:course_statistics).get({
            course_id: course_id,
            historic_data: true,
            start_date: course['created_at'],
            end_date:,
          }).value!
        rescue StandardError => e
          Rails.logger.warn("Failed to fetch historic course statistics: #{e.message}")
          []
        end

        course_statistics.map do |stats|
          timestamp = stats['updated_at']&.to_date

          {
            timestamp:,
            total_enrollments: stats['total_enrollments'],
          }
        end
      end
    end
  end
end
