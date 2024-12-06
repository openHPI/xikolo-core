# frozen_string_literal: true

module Course
  class CircularProgress < ApplicationComponent
    def initialize(value, label, size = nil)
      @value = value
      @label = label
      @size = size
    end

    def css_modifiers
      [].tap do |modifiers|
        modifiers << 'circular-progress--small' if @size == :small
        modifiers << 'circular-progress--small__label' if @size == :small
      end.join(' ')
    end
  end
end
