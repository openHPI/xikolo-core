# frozen_string_literal: true

module State
  class Empty < ApplicationComponent
    def initialize(text, size: nil)
      @text = text
      @size = size
    end

    def css_modifiers
      "empty-state--#{@size}" if @size == :small
    end
  end
end
