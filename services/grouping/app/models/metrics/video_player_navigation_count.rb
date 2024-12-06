# frozen_string_literal: true

module Metrics
  class VideoPlayerNavigationCount < LanalyticsCountMetric
    def set_name
      self.name ||= 'VideoPlayerNavigationCount'
    end

    def self.show
      true
    end
  end
end
