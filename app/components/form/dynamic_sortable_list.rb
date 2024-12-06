# frozen_string_literal: true

module Form
  class DynamicSortableList < ApplicationComponent
    def initialize(list_items, name: '', input_id: '', select_config: {})
      @list_items = list_items
      @name = name
      @input_id = input_id
      @select_config = select_config
    end

    def add_items?
      @input_id.present? || @select_config.present?
    end

    def select_url
      @select_config[:url]
    end

    def select_placeholder
      @select_config[:placeholder]
    end

    def select_preload
      'true' if @select_config[:preload]
    end
  end
end
