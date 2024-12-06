# frozen_string_literal: true

module Global
  class DisclosureWidget < ApplicationComponent
    def initialize(summary, content_lang: nil, expanded_summary: nil, visible: true)
      @summary = summary

      @content_lang = content_lang
      @expanded_summary = expanded_summary
      @visible = visible
    end

    def expanded_summary
      @expanded_summary || @summary
    end

    private

    def render?
      @visible
    end
  end
end
