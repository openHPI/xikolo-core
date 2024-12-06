# frozen_string_literal: true

module Home
  class HeadHero < ApplicationComponent
    def initialize(text, call_to_action: {}, image: {}, size: 'xl')
      @text = text
      @call_to_action = call_to_action
      @image = image
      @size = size
    end

    def image
      return if @image[:url].blank?

      {
        url: view_context.image_url(@image[:url]),
        alt: @image[:alt] || '',
      }
    end

    def css_modifiers
      "head-hero--#{@size}" if %w[xl l].include? @size
    end

    def js_hook
      'head-hero-image' if @image[:dim_nav_logo].present?
    end
  end
end
