# frozen_string_literal: true

module Metrics
  class PinboardPostingActivity < LanalyticsCountMetric
    def set_name
      self.name ||= 'PinboardPostingActivity'
    end

    def self.show
      true
    end
  end
end
