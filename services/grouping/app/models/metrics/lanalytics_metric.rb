# frozen_string_literal: true

module Metrics
  class LanalyticsMetric < Metric
    def self.query(user_id, course_id = nil, start_date = nil, end_date = nil)
      options = {name: metric_name,
                 user_id:,
                 course_id:,
                 start_date:,
                 end_date:}.compact
      Xikolo.api(:learnanalytics).value!.rel(:metric).get(options).value!
    end

    def self.metric_name
      sti_name
    end

    def set_distribution
      self.distribution ||= :normal
    end
  end
end
