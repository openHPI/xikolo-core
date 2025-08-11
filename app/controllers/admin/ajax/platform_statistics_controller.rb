# frozen_string_literal: true

module Admin
  module Ajax
    class PlatformStatisticsController < Abstract::AjaxController
      require_permission 'global.dashboard.show'

      def learners_and_enrollments
        data = Rails.cache.fetch('platform_statistics/learners_and_enrollments/', expires_in: 1.hour,
          race_condition_ttl: 1.minute) do
          Restify::Promise.new([
            account_api.rel(:statistics).get,
            course_api.rel(:stats).get({key: 'global'}),
          ]) do |account_stats, course_stats|
            total_enrollments = course_stats['platform_enrollments'] +
                                course_stats['platform_enrollment_delta_sum'] +
                                Xikolo.config.global_enrollment_delta
            confirmed_users = account_stats['confirmed_users'] + Xikolo.config.global_users_delta

            {
              confirmed_users:,
              confirmed_users_last_day: account_stats['confirmed_users_last_day'],
              deleted_users: account_stats['users_deleted'],
              total_enrollments:,
              total_enrollments_last_day: course_stats['platform_last_day_enrollments'],
              courses_count: course_stats['courses_count'],
            }
          end.value!
        end

        render json: data
      end

      def activity
        fetch_active_users = lambda {|start_date, end_date|
          fetch_metric(name: 'active_user_count', start_date:, end_date:)
            .then {|response| response&.dig('active_users') }
        }

        data = Rails.cache.fetch('platform_statistics/activity/', expires_in: 30.minutes,
          race_condition_ttl: 1.minute) do
          Restify::Promise.new([
            fetch_active_users.call(24.hours.ago, Time.zone.now),
            fetch_active_users.call(7.days.ago, Time.zone.now),
          ]) do |count_24h, count_7days|
            {
              count_24h:,
              count_7days:,
            }
          end.value!
        end

        render json: data
      end

      def certificates
        data = Rails.cache.fetch('platform_statistics/certificates/', expires_in: 1.hour,
          race_condition_ttl: 30.seconds) do
          certs = fetch_metric(name: 'certificates').value!
          {
            roa_count: certs['record_of_achievement'],
            cop_count: certs['confirmation_of_participation'],
          }
        end

        render json: data
      end
    end
  end
end
