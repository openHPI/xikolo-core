# frozen_string_literal: true

module Admin
  module Statistics
    module MetricHelpers
      private

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
