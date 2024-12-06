# frozen_string_literal: true

module Global
  class LabeledCopyButton < ApplicationComponent
    def initialize(label:, value:, button:)
      @label = label
      @value = value
      @button = button
    end
  end
end
