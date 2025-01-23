# frozen_string_literal: true

module Global
  class DisclosureWidget < ApplicationComponent
    def initialize(summary, content_lang: nil, expanded_summary: nil, visible: true, variant: :default, icons: {})
      @summary = summary

      @content_lang = content_lang
      @expanded_summary = expanded_summary
      @visible = visible
      @variant = variant
      @icons = icons
    end

    def expanded_summary
      @expanded_summary || @summary
    end

    def icons
      {
        opened: @icons[:opened] || 'chevron-down',
        closed: @icons[:closed] || 'chevron-right',
        opened_classes: @icons[:opened_classes] || 'mr5',
        closed_classes: @icons[:closed_classes] || 'mr10',
        style: @icons[:opened_style] || :solid,
      }
    end

    def css_classes
      if @variant == :light
        'disclosure-widget--light'
      end
    end

    private

    def render?
      @visible
    end

    def variant
      @variant if %w[default light].include?(@variant)
    end
  end
end
