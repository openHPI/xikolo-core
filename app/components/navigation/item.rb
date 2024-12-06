# frozen_string_literal: true

module Navigation
  class Item < ApplicationComponent
    def initialize(
      text: nil,
      tooltip: nil,
      icon: {},
      link: {},
      active: nil,
      locked: false,
      type: nil,
      lang: nil
    )
      @text = text
      @tooltip = tooltip
      @icon = icon
      @link = link
      @active = active
      @locked = locked
      @type = type
      @lang = lang
    end

    attr_accessor :type

    renders_many :items, ->(*args, **kwargs) do
      if args.first.is_a?(self.class)
        args.first
      else
        self.class.new(**kwargs)
      end
    end

    ##
    # Is this item active?
    #
    # This method is public to allow dropdowns to check their children items
    # for their active state.
    def active?
      return @active unless @active.nil?

      items.present? ? items.any?(&:active?) : false
    end

    def tooltip
      @tooltip.presence
    end

    def icon_code
      if locked?
        'lock'
      else
        @icon[:code]
      end
    end

    private

    def css_classes
      %w[navigation-item].tap do |cls|
        cls << "navigation-item--#{item_type}" if item_type.present?
      end.join(' ')
    end

    def action_css_classes
      %w[navigation-item__main].tap do |cls|
        cls << 'btn-as-text' if menu?
        cls << 'navigation-item__main--link' if @link.present?
        cls << 'navigation-item__main--active' if active?
        cls << 'navigation-item__main--locked' if locked?
      end.join(' ')
    end

    def item_type
      @item_type ||= if %w[hide-first hide-last menu-hide-first menu-hide-last].include? @type
                       @type
                     end
    end

    def icon?
      # To render an icon its Font Awesome code is required. Optionally,
      # the aria-label can be used. e.g: icon: {code: 'globe', aria_label: 'Choose language'}
      # If the item is locked, the icon will be a lock icon.
      @icon[:code].present? || locked?
    end

    def rel
      @link[:target] == '_blank' ? 'noopener' : ''
    end

    def aria_label
      @icon[:aria_label] if @text.blank?
    end

    def aria_description
      @icon[:aria_label] if @text.present?
    end

    def menu?
      items.present?
    end

    def controls?
      menu? && !icon?
    end

    def locked?
      @locked
    end

    def aria_controls
      "navdropdown-#{object_id}"
    end

    def aria_current
      'page' if active?
    end
  end
end
