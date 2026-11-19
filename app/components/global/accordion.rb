# frozen_string_literal: true

module Global
  class Accordion < ApplicationComponent
    def initialize(headline: nil, variant: nil)
      @headline = headline
      @variant = variant
    end

    renders_many :sections, ->(label, id, expanded: false, locked: false) do
      AccordionSection.new(label, id, expanded:, locked:, variant:, name: section_group)
    end

    private

    def variant
      @variant == 'slim' ? 'slim' : 'default'
    end

    def section_group
      @section_group ||= "accordion-#{SecureRandom.uuid}"
    end
  end
end
