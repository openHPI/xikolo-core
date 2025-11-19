# frozen_string_literal: true

module Admin
  module Statistics
    class LearnersAndEnrollments < ApplicationOperation
      include MetricHelpers

      def call
        Restify::Promise.new([
          account_api.rel(:statistics).get,
          course_api.rel(:stats).get({key: 'global'}),
        ]) do |account_stats, course_stats|
          if account_stats.blank? || course_stats.blank?
            next {}
          end

          total_enrollments = course_stats['platform_enrollments'] +
                              course_stats['platform_enrollment_delta_sum'] +
                              Xikolo.config.global_enrollment_delta
          confirmed_users = account_stats['confirmed_users'] + Xikolo.config.global_users_delta

          {
            'confirmed_users' => confirmed_users,
            'confirmed_users_last_day' => account_stats['confirmed_users_last_day'],
            'deleted_users' => account_stats['users_deleted'],
            'total_enrollments' => total_enrollments,
            'total_enrollments_last_day' => course_stats['platform_last_day_enrollments'],
            'courses_count' => course_stats['courses_count'],
          }
        end.value! || {}
      end
    end
  end
end
