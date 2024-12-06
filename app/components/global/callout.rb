# frozen_string_literal: true

module Global
  class Callout < ApplicationComponent
    def initialize(text, type: nil, title: nil, icon: nil)
      @text = text
      @title = title
      @type = type
      @icon = icon
    end

    private

    def render?
      @text.present?
    end

    def css_modifiers
      css_modifiers = @title ? 'callout--with-title' : nil
      @type ? "callout--#{@type} #{css_modifiers} " : css_modifiers
    end

    def icon
      @icon || Global::FaIcon.new(default_icon_name, style: :solid)
    end

    def default_icon_name
      {
        success: 'circle-check',
        error: 'circle-exclamation',
        warning: 'triangle-exclamation',
      }[@type] || 'circle-info'
    end
  end
end
