# frozen_string_literal: true

module Global
  class Meter < ApplicationComponent
    def initialize(value:, label: nil, type: nil)
      @value = value
      @label = label
      @type = type
      @component_id = SecureRandom.uuid
    end

    attr_reader :value, :label, :component_id

    def css_classes
      'meter--info' if @type == :info
    end
  end
end
