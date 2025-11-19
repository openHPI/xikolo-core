# frozen_string_literal: true

module Global
  class KpiScoreCard < ApplicationComponent
    # @param title [String] the card title
    # @param value [String, Integer] the metric value
    # @param icon_class [String] FontAwesome icon class
    # @param format [Symbol] format type: :count (default) or :percentage
    # @param more_details_url [String, nil] optional URL for more details link
    # @param heading_level [Integer, nil] optional ARIA heading level (1..6); defaults to nil
    def initialize(title:, value:, icon_class:, format: :count, more_details_url: nil, heading_level: nil)
      @title = title
      @raw_value = value
      @icon_class = icon_class
      @format = format
      @more_details_url = more_details_url
      @heading_level = heading_level
    end

    attr_reader :title, :icon_class, :more_details_url, :heading_level

    def formatted_value
      return 'n/a' if @raw_value.blank?

      case @format
        when :percentage
          helpers.number_to_percentage(@raw_value * 100, precision: 2)
        else # :count
          helpers.number_with_delimiter(@raw_value)
      end
    end

    def more_details?
      more_details_url.present?
    end
  end
end
