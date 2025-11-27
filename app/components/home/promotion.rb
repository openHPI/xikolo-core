# frozen_string_literal: true

module Home
  class Promotion < ApplicationComponent
    def initialize(title, text, **options)
      @title = title
      @text = text
      @link_url = options[:link_url]
      @target = options[:target]
      @download = options[:download]
      @variant = options[:variant] || :secondary
      @overlay_opacity = options[:overlay_opacity] || 0.5
      @image_url = options[:image_url]
    end

    private

    def css_modifiers
      [].tap do |modifiers|
        modifiers << 'promotion--with-image' if @image_url.present?
        modifiers << "promotion--#{@variant}" if @variant
      end.join(' ')
    end

    def overlay_modifier
      "promotion__overlay--#{@variant}" if @variant
    end

    def link?
      @link_url.present?
    end

    def image?
      @image_url.present?
    end

    def image
      "background-image: url('#{@image_url}');"
    end

    def overlay_opacity
      "opacity: #{@overlay_opacity}"
    end

    def link_options
      {}.tap do |options|
        if @target == 'blank'
          options[:target] = '_blank'
          options[:rel] = 'noopener'
        end
        if @download
          options[:download] = @download.is_a?(String) ? @download : true
        end
      end
    end

    def link_icon_target_options
      link_options.merge('aria-label': t(:'components.promotion.link')).tap do |options|
        options[:download] = @download if @download
      end
    end
  end
end
