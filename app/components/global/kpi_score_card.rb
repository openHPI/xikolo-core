# frozen_string_literal: true

module Global
  class KpiScoreCard < ApplicationComponent
    # @param title [String] the card title
    # @param value [String, Integer] the metric value
    # @param icon_class [String] FontAwesome icon class
    # @param more_details_url [String, nil] optional URL for more details link
    # @param heading_level [Integer, nil] optional ARIA heading level (1..6); defaults to nil
    def initialize(title:, value:, icon_class:, more_details_url: nil, heading_level: nil)
      @title = title
      @value = value
      @icon_class = icon_class
      @more_details_url = more_details_url
      @heading_level = heading_level
    end

    attr_reader :title, :value, :icon_class, :more_details_url, :heading_level

    def more_details?
      more_details_url.present?
    end
  end
end
