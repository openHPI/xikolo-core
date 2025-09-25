# frozen_string_literal: true

module Admin
  module Statistics
    class ClientUsage < ApplicationOperation
      def initialize(course_id: nil, start_date: nil, end_date: nil)
        super()

        @course_id = course_id
        @start_date = start_date
        @end_date = end_date
      end

      def call
        usage = fetch_client_usage(@course_id, @start_date, @end_date)
        return [] if usage.blank?

        # Drop rows with no users and 0% share
        filtered = usage.reject do |e|
          e['total_users'].to_i.zero? && e['relative_users'].to_f.zero?
        end

        filtered.map do |entry|
          {
            'client_types' => Array(entry['client_types']).map {|t| t.to_s.humanize.titleize }.join(' + '),
            'total_users' => entry['total_users'],
            'relative_users' => format('%0.1f%%', entry['relative_users'].to_f),
          }
        end
      end

      private

      def fetch_client_usage(course_id, start_date, end_date)
        params = {
          name: 'client_combination_usage',
          course_id:,
          start_date: start_date.presence || 1.month.ago,
          end_date: end_date.presence || Time.zone.now,
        }.compact

        return nil unless client_usage_available?

        Xikolo.api(:learnanalytics).value!
          .rel(:metric).get(params).value!
      rescue StandardError
        nil
      end

      def client_usage_available?
        @client_usage_available ||= begin
          metrics_list = Xikolo.api(:learnanalytics).value!
            .rel(:metrics).get.value!
          metrics_list.any? {|metric| metric['name'] == 'client_combination_usage' && metric['available'] }
        end
      end
    end
  end
end
