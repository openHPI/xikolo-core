# frozen_string_literal: true

module Metrics
  class CourseActivity < LanalyticsCountMetric
    def set_name
      self.name ||= 'CourseActivity'
    end

    def self.show
      true
    end
  end
end
