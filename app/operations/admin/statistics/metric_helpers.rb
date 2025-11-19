# frozen_string_literal: true

module Admin
  module Statistics
    module MetricHelpers
      private

      def fetch_metric(name:, **params)
        return Restify::Promise.fulfilled(nil) unless metrics_available?(name)

        api = lanalytics_api
        return Restify::Promise.fulfilled(nil) unless api

        api.rel(:metric).get({**params, name:})
      end

      def metrics_available?(*names)
        names.map(&:underscore).all? {|name| available_metrics.include?(name) }
      end

      def available_metrics
        return @available_metrics if defined?(@available_metrics)

        api = lanalytics_api
        unless api
          return []
        end

        begin
          metrics_list = api.rel(:metrics).get.value!
          @available_metrics = metrics_list.select {|metric| metric['available'] }.pluck('name')
        rescue StandardError => e
          Rails.logger.warn("Failed to fetch available metrics: #{e.message}")
          []
        end
      end

      def lanalytics_api
        @lanalytics_api ||= begin
          Xikolo.api(:learnanalytics).value!
        rescue StandardError => e
          Rails.logger.warn("Failed to initialize lanalytics API: #{e.message}")
          nil
        end
      end

      def account_api
        @account_api ||= Xikolo.api(:account).value!
      end

      def course_api
        @course_api ||= Xikolo.api(:course).value!
      end

      def quiz_api
        @quiz_api ||= Xikolo.api(:quiz).value!
      end

      def pinboard_api
        @pinboard_api ||= Xikolo.api(:pinboard).value!
      end
    end
  end
end
