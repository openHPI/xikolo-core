# frozen_string_literal: true

module Global
  class KpiCard < ApplicationComponent
    # @param icon_class [String] FontAwesome icon class
    # @param title [String]
    # @param metrics [Array<Hash>] hashes with keys :counter, :title, optional :quota, :quota_text
    # @param empty_message [String, nil]
    # @param heading_level [Integer, nil] optional ARIA heading level (1..6); defaults to nil
    def initialize(icon_class:, title:, metrics: [], empty_message: nil, heading_level: nil)
      @icon_class = icon_class
      @title = title
      @metrics = metrics
      @empty_message = empty_message
      @heading_level = heading_level
    end

    attr_reader :icon_class, :title, :metrics, :empty_message, :heading_level
  end
end
