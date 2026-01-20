# frozen_string_literal: true

module Home
  class CoursesSliderPreview < ViewComponent::Preview
    def default
      render Home::CoursesSlider.new(current_and_upcoming_category:)
    end

    def light
      render Home::CoursesSlider.new(current_and_upcoming_category:, slider_variant: :light)
    end

    private

    def current_and_upcoming_category
      Catalog::Category::CurrentAndUpcoming.new
    end
  end
end
