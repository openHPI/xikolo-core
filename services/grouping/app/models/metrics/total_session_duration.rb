# frozen_string_literal: true

module Metrics
  class TotalSessionDuration < LanalyticsMetric
    def set_name
      self.name ||= 'TotalSessionDuration'
    end

    def self.show
      true
    end
  end
end
