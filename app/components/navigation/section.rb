# frozen_string_literal: true

module Navigation
  class Section < ApplicationComponent
    renders_many :segments, types: {unit: Navigation::SectionUnit, section: Navigation::Section}

    def initialize(text:, link: {}, active: false, locked: false, progress: nil, lang: nil)
      @text = text
      @link = link || {}
      @active = active
      @locked = locked
      @progress = progress # [Hash, nil] the number of completed and total units, e.g. `{completed: 1, total: 2}`
      @lang = lang
    end

    private

    # Sections with segments expand in place, all others are plain links (if accessible).
    def expandable?
      segments?
    end

    def header_tag
      href? ? :a : :div
    end

    def header_attributes
      attributes = {lang: @lang}
      return attributes unless href?

      attributes.merge(href: @link[:href], aria: {current: ('page' if @active)}, data: {turbo: false})
    end

    def card_modifier_classes
      @active ? nil : 'border border-base-300'
    end

    def header_modifier_classes
      class_names(
        @locked ? 'text-base-content/60' : 'text-base-content',
        @locked && !href? ? 'cursor-not-allowed' : nil,
        @active ? 'bg-accent-50' : nil,
        href? && !@active ? 'hover:bg-base-200' : nil,
        href? ? 'focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-accent' : nil
      )
    end

    def href?
      @link[:href].present?
    end
  end
end
