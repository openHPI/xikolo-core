# frozen_string_literal: true

module Course
  # A course item with the learner's progress on it.
  # Rendered as a compact card (e.g. in a carousel) or as a full-width row.
  class ItemCard < ApplicationComponent
    STATE_CLASSES = {
      default: 'bg-base-100 border-base-200 text-base-content',
      completed: 'bg-success border-success text-base-content',
      failed: 'bg-error border-error text-error-50',
      current: 'bg-accent-25 border-accent text-base-content',
      locked: 'bg-base-200 border-base-300 text-base-content',
    }.freeze

    LAYOUTS = %i[card row].freeze

    # @param title [String]
    # @param label [String] human-readable item type, e.g. "Exam"
    # @param icon [String] pixelart icon name of the item type
    # @param path [String, nil] link to the item; locked items are linked when
    #   their page explains why they are locked
    # @param state [Symbol] :default, :completed, :failed, :current or :locked
    # @param layout [Symbol] :card or :row
    # @param action_label [String, nil] call to action of the current or a
    #   failed item, e.g. "Continue" or "Retake"
    def initialize(title:, label:, icon:, path: nil, state: :default, layout: :card, action_label: nil)
      @title = title
      @label = label
      @icon = icon
      @path = path
      @state = state.to_sym
      @layout = layout.to_sym
      @action_label = action_label

      raise ArgumentError.new("Unknown state: #{state}") unless STATE_CLASSES.key?(@state)
      raise ArgumentError.new("Unknown layout: #{layout}") unless LAYOUTS.include?(@layout)
    end

    private

    def tag_name
      link? ? :a : :div
    end

    def href
      @path if link?
    end

    def link?
      @path.present?
    end

    # Opening an item counts as the learner's visit, which a prefetch on hover
    # does not. Clicking would show the prefetched page, without the visit.
    def turbo_prefetch
      false if link?
    end

    def row?
      @layout == :row
    end

    def completed?
      @state == :completed
    end

    def locked?
      @state == :locked
    end

    def current?
      @state == :current
    end

    def failed?
      @state == :failed
    end

    def action?
      (current? || failed?) && @action_label.present?
    end

    # The learner's current step in the course, e.g. their last visited item.
    def aria_current
      'step' if current?
    end

    # The row layout stacks its content on small screens and lines it up from `md`.
    def container_classes
      layout_classes = row? ? 'p-3 md:flex-row md:items-center md:gap-16 md:px-6' : 'h-full w-full p-4'

      ['x-card border', layout_classes, STATE_CLASSES.fetch(@state)]
    end

    def content_classes
      row? ? 'flex flex-col gap-2 md:flex-row md:items-center md:gap-6' : 'flex flex-col gap-2'
    end

    def icon_name
      locked? ? 'lock' : @icon
    end

    # Marks completed and failed items, as their colors alone do not tell.
    def mark_icon
      completed? ? 'check' : 'close'
    end

    # The failed mark is inverted, as the failed item is red itself.
    def mark_classes
      completed? ? 'border-base-300 bg-accent text-white' : 'border-error-50 bg-error-50 text-error'
    end

    def mark_label
      t(completed? ? 'course.item_card.completed' : 'course.item_card.failed')
    end

    def icon_classes
      row? ? 'size-4 shrink-0 md:size-7' : 'size-6 shrink-0'
    end

    def badge_classes
      row? ? 'x-badge-xs md:x-badge-md' : nil
    end

    def title_classes
      row? ? 'font-medium md:font-normal' : nil
    end

    # daisyUI outline buttons are colored by their own variables, not the text
    # color: light on the red failed item, turning red on a light fill on hover.
    def action_classes
      failed? ? '[--x-btn-color:var(--color-error-50)] [--x-btn-fg:var(--color-error)]' : nil
    end

    def indicator_classes
      row? ? 'absolute top-2.25 right-3 md:static md:ms-auto' : 'absolute top-2.25 right-4'
    end
  end
end
