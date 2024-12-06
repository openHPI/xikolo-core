# frozen_string_literal: true

module Home
  class CoursesSlider < ApplicationComponent
    def initialize(courses = [], href: nil, title: nil, slider_variant: :dark)
      @courses = courses
      @title = title
      @href = href
      @slider_variant = slider_variant
    end

    def render?
      @courses.any?
    end
  end
end
