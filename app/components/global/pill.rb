# frozen_string_literal: true

module Global
  class Pill < ApplicationComponent
    def initialize(text, size: nil, color: nil)
      @text = text
      @size = size
      @color = color
    end

    def call
      tag.p class: "pill #{css_modifiers}" do
        @text
      end
    end

    def css_modifiers
      [].tap do |modifiers|
        modifiers << 'pill--small' if @size == :small
        modifiers << "pill--#{@color}" if %i[note success information error].include?(@color)
      end.join(' ')
    end
  end
end
