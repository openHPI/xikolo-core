# frozen_string_literal: true

module Global
  class AccordionSection < ApplicationComponent
    # Tailwind z-index value applied to the section so overlapping sections stack
    # with the first section on top. Set by the parent Global::Accordion.
    attr_writer :z_index

    # Content rendered in the header, next to the chevron (e.g. badges or icons).
    renders_one :header
    # Content rendered below the section content (e.g. navigation).
    renders_one :footer

    def initialize(
      label,
      id,
      expanded: false,
      variant: 'default',
      name: nil,
      locked: false
    )
      @label = label
      @id = id
      @expanded = expanded
      @locked = locked
      @variant = variant
      @name = name
    end

    renders_one :header_detail
    renders_one :indicator

    private

    # Locked sections cannot be opened, so they render no disclosure widget and no content.
    def locked?
      @locked
    end

    def color_classes
      if @variant == 'slim'
        'border-accent-50 bg-accent-10'
      else
        'border-info bg-base-100 open:border-secondary-75'
      end
    end

    def title_classes
      @variant == 'slim' ? 'min-h-14 text-base font-medium' : 'min-h-17 text-xl font-semibold'
    end
  end
end
