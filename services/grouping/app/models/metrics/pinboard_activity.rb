# frozen_string_literal: true

module Metrics
  class PinboardActivity < LanalyticsCountMetric
    def set_name
      self.name ||= 'PinboardActivity'
    end

    def self.show
      true
    end
  end
end
