# frozen_string_literal: true

module Admin
  module Statistics
    class HistoricData < ApplicationOperation
      def initialize(course_id: nil)
        super()

        @course_id = course_id
      end

      def call
        data = fetch_historic_data(@course_id)
        return [] if data.blank?

        data.map do |entry|
          {
            'total_enrollments' => entry[:total_enrollments],
          }
        end
      end

      private

      def fetch_historic_data(course_id)
        course = Xikolo.api(:course).value!.rel(:course).get({id: course_id}).value!

        end_date =
          if course['end_date'].blank? || DateTime.parse(course['end_date']).future?
            DateTime.now
          else # end_date is in the past
            DateTime.parse(course['end_date']) + 12.weeks
          end

        course_statistics = Xikolo.api(:learnanalytics).value!.rel(:course_statistics).get({
          course_id: course_id,
        historic_data: true,
        start_date: course['created_at'],
        end_date:,
        }).value!

        course_statistics.map do |stats|
          {
            timestamp: stats['updated_at'].to_date,
              total_enrollments: stats['total_enrollments'],
              current_enrollments: stats['current_enrollments'],
              enrollments_last_day: stats['enrollments_last_day'],
              new_users: stats['new_users'],
              no_shows: stats['no_shows'],
              active_users_last_day: stats['active_users_last_day'],
              active_users_last_7days: stats['active_users_last_7days'],
              posts: stats['posts'],
              threads: stats['threads'],
              helpdesk_tickets: stats['helpdesk_tickets'],
          }
        end
      end
    end
  end
end
