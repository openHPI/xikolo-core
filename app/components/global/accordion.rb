# frozen_string_literal: true

module Global
  class Accordion < ApplicationComponent
    def initialize(headline: nil)
      @headline = headline
    end

    renders_many :sections, AccordionSection
  end
end
