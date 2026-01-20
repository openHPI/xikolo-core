# frozen_string_literal: true

module Home
  class CoursesSlider < ApplicationComponent
    attr_reader :slider_variant

    def initialize(current_and_upcoming_category:, slider_variant: :dark)
      @current_and_upcoming_category = current_and_upcoming_category
      @slider_variant = slider_variant
    end

    def courses
      @current_and_upcoming_category.courses
    end

    def title
      @current_and_upcoming_category.title
    end

    def href
      @current_and_upcoming_category.url
    end

    def render?
      courses.any?
    end
  end
end
