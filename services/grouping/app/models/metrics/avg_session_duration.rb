# frozen_string_literal: true

module Metrics
  class AvgSessionDuration < LanalyticsMetric
    def set_name
      self.name ||= 'AvgSessionDuration'
    end

    def self.show
      true
    end
  end
end
