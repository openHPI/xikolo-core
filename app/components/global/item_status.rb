# frozen_string_literal: true

module Global
  class ItemStatus < ApplicationComponent
    def initialize(item, connected_type: '', color_scheme: '')
      @text = item[:text]
      @title = item[:title]
      @path = item[:path]
      @tooltip = item[:tooltip]
      @icon_name = item[:icon_name]

      @color_scheme = color_scheme
      @connected_type = connected_type
    end

    def css_classes
      css_classes = %w[item-status]

      if connected_type.present?
        css_classes << 'item-status--connected'
        css_classes << "item-status--#{connected_type}"
      end

      css_classes << "item-status--#{color_scheme}" if color_scheme.present?

      css_classes
    end

    def data_attributes
      {tooltip: @tooltip} if @tooltip.present?
    end

    private

    def color_scheme
      @color_scheme if %w[success error link].include?(@color_scheme)
    end

    def connected_type
      @connected_type if %w[default filled dashed disabled].include?(@connected_type)
    end

    def icon
      Global::FaIcon.new(@icon_name)
    end
  end
end
