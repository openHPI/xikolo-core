# frozen_string_literal: true

module Metrics
  class PinboardWatchCount < LanalyticsCountMetric
    def set_name
      self.name ||= 'PinboardWatchCount'
    end

    def self.show
      true
    end
  end
end
