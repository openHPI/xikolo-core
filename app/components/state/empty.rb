# frozen_string_literal: true

module State
  class Empty < ApplicationComponent
    SIZES = %i[small compact].freeze
    POSITIONS = %i[left].freeze

    def initialize(text, size: nil, align: nil)
      @text = text
      @size = size
      @align = align
    end

    def css_modifiers
      modifiers = []
      modifiers << "empty-state--#{@size}" if SIZES.include?(@size)
      modifiers << "empty-state--#{@align}" if POSITIONS.include?(@align)
      modifiers.join(' ')
    end
  end
end
