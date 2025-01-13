# frozen_string_literal: true

module Global
  class Meter < ApplicationComponent
    def initialize(value:, label: nil, type: nil, background_color: nil)
      @value = value
      @label = label
      @type = type
      @background_color = background_color
      @component_id = SecureRandom.uuid
    end

    attr_reader :value, :label, :component_id

    def css_classes
      [].tap do |modifiers|
        modifiers << 'meter--info' if @type == :info
        modifiers << 'meter--white' if @background_color == :white
      end
    end
  end
end
