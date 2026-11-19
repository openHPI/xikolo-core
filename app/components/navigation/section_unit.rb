# frozen_string_literal: true

module Navigation
  class SectionUnit < ApplicationComponent
    def initialize(text:, link: {}, icon: nil, active: false, locked: false, completed: false, deemphasized: false,
                   lang: nil)
      @text = text
      @link = link || {}
      @icon = icon
      @active = active
      @locked = locked
      @completed = completed
      @deemphasized = deemphasized
      @lang = lang
    end

    private

    def tag_name
      href? ? :a : :div
    end

    def tag_attributes
      attributes = {lang: @lang}
      return attributes unless href?

      attributes.merge(href: @link[:href], aria: {current: ('page' if @active)}, data: {turbo: false})
    end

    def modifier_classes
      class_names(
        @active ? 'font-medium' : 'font-normal',
        @locked || @deemphasized ? 'text-base-content/60' : 'text-base-content',
        @locked && !href? ? 'cursor-not-allowed' : nil,
        href? ? 'hover:underline focus-visible:outline-2 focus-visible:outline-accent' : nil
      )
    end

    def href?
      @link[:href].present?
    end
  end
end
