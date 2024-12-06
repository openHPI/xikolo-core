# frozen_string_literal: true

module Global
  module FilterBar
    class Filter < ApplicationComponent
      attr_reader :key, :options, :selected, :visible

      def initialize(key, title, options, selected: nil, visible: true,
                     blank_option: nil, multi_select: false)
        @key = key
        @title = title
        @options = options
        @selected = selected
        @visible = visible
        @blank_option = blank_option
        @multi_select = multi_select
      end

      def render?
        @visible || disabled?
      end

      def disabled?
        !@visible && @selected
      end

      def include_blank
        @blank_option.presence || t(:'components.filter_bar.filter.all')
      end

      def disabled_select_text
        if @options.is_a?(Hash)
          @options.key(@selected) || @selected
        else
          @selected
        end
      end
    end
  end
end
