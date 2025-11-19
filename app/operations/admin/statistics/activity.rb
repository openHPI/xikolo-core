# frozen_string_literal: true

module Admin
  module Statistics
    class Activity < ApplicationOperation
      include MetricHelpers

      def call
        Restify::Promise.new([
          active_users(24.hours.ago, Time.zone.now),
          active_users(7.days.ago, Time.zone.now),
        ]) do |count_24h, count_7days|
          {
            'count_24h' => count_24h,
            'count_7days' => count_7days,
          }
        end.value! || {}
      end

      private

      def active_users(start_date, end_date)
        fetch_metric(name: 'active_user_count', start_date:, end_date:)
          .then {|response| response&.dig('active_users') }
      end
    end
  end
end
