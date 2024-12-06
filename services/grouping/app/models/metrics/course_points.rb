# frozen_string_literal: true

module Metrics
  class CoursePoints < LanalyticsMetric
    def self.query(user_id, course_id, start_date, end_date)
      super['points']
    end

    def set_name
      self.name ||= 'CoursePoints'
    end

    def self.show
      true
    end
  end
end
