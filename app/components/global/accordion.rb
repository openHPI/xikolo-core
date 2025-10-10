# frozen_string_literal: true

module Global
  class Accordion < ApplicationComponent
    def initialize(headline: nil, variant: nil)
      @headline = headline
      @variant = variant
    end

    renders_many :sections, AccordionSection

    private

    def variant
      @variant if %w[default slim].include?(@variant)
    end
  end
end
