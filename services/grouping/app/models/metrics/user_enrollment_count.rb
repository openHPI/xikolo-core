# frozen_string_literal: true

module Metrics
  # Counts the total number of enrollments for one user
  class UserEnrollmentCount < LanalyticsCountMetric
    def set_name
      self.name ||= 'UserEnrollmentCount'
    end

    def self.show
      true
    end
  end
end
