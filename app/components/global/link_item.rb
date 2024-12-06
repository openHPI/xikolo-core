# frozen_string_literal: true

module Global
  class LinkItem < ApplicationComponent
    def initialize(text:, href:, active: false, title: nil, target: nil, icon_class: nil)
      @text = text
      @href = href
      @active = active
      @title = title
      @target = target
      @icon_class = icon_class
    end

    private

    def css_classes
      @active ? 'active' : ''
    end

    def title
      @title.presence || @text
    end

    def target
      @target.presence
    end

    def rel
      target == '_blank' ? 'noopener' : ''
    end

    def icon?
      @icon_class.present?
    end

    def icon
      Global::FaIcon.new(@icon_class)
    end
  end
end
