# frozen_string_literal: true

module Global
  class CopyToClipboard < ApplicationComponent
    def initialize(text, label: nil, tooltip: nil, type: :icon)
      @text = text
      @label = label
      @tooltip = tooltip
      @type = type
    end

    def css_classes
      if type == :button
        'clipboard btn btn-default btn-outline btn-xs'
      else
        'clipboard clipboard--icon'
      end
    end

    private

    def type
      @type if %i[icon button].include?(@type)
    end
  end
end
