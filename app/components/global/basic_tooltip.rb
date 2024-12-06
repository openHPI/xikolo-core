# frozen_string_literal: true

module Global
  class BasicTooltip < ApplicationComponent
    def initialize(text)
      @texts = Array.wrap(text)
    end
  end
end
