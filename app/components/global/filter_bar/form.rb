# frozen_string_literal: true

module Global
  module FilterBar
    class Form < ApplicationComponent
      renders_one :controls, ->(content_id: nil, loading_indicator_id: nil) do
        Controls.new(@action, content_id, loading_indicator_id, @filters, search_param: @search_param)
      end

      def initialize(action:, filters:, search_param: :q, search_label: nil, search_value: nil)
        @action = action
        @filters = filters
        @search_param = search_param
        @search_label = search_label
        @search_value = search_value
        @filters_id = "filter-bar-filters-#{object_id}"
      end
    end
  end
end
