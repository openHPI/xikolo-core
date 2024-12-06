# frozen_string_literal: true

module Metrics
  class VideoVisitCount < LanalyticsCountMetric
    def set_name
      self.name ||= 'VideoVisitCount'
    end

    def self.show
      true
    end
  end
end
