# frozen_string_literal: true

module Metrics
  class LanalyticsCountMetric < LanalyticsMetric
    def self.query(user_id, course_id, start_date, end_date)
      super['count']
    end
  end
end
