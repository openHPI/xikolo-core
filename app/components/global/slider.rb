# frozen_string_literal: true

module Global
  class Slider < ApplicationComponent
    renders_many :items

    def initialize(variant: :light)
      @variant = variant
    end

    def css_modifiers
      "slider--#{@variant}"
    end
  end
end
