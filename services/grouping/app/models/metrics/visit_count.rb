# frozen_string_literal: true

module Metrics
  class VisitCount < LanalyticsCountMetric
    def set_name
      self.name ||= 'VisitCount'
    end

    def self.show
      true
    end
  end
end
