# frozen_string_literal: true

module Metrics
  class VideoPlayerSeekCount < LanalyticsCountMetric
    def set_name
      self.name ||= 'VideoPlayerSeekCount'
    end

    def self.show
      true
    end
  end
end
