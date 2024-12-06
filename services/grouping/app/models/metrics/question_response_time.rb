# frozen_string_literal: true

module Metrics
  class QuestionResponseTime < LanalyticsCountMetric
    def set_name
      self.name ||= 'QuestionResponseTime'
    end

    def self.show
      true
    end
  end
end
