# frozen_string_literal: true

module Metrics
  class Sessions < LanalyticsMetric
    def set_name
      self.name ||= 'Sessions'
    end

    def self.show
      true
    end
  end
end
