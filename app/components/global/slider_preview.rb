# frozen_string_literal: true

module Global
  class SliderPreview < ViewComponent::Preview
    def light_variant
      render_with_template(template: 'global/slider_preview/with_courses',
        locals: {variant: :light, courses: example_courses})
    end

    # @display bg_color "#262626"
    def dark_variant
      render_with_template(template: 'global/slider_preview/with_courses',
        locals: {variant: :dark, courses: example_courses})
    end

    # Use the colors defined in app/assets/stylesheets/theme/common/_variables.scss.
    # Can be overriden per brand.
    def custom_variant
      render_with_template(template: 'global/slider_preview/with_courses',
        locals: {variant: :custom, courses: example_courses})
    end

    private

    def example_courses
      (1..10).map {|title| course(title) }
    end

    def course(title)
      Catalog::Course.new({
        id: SecureRandom.uuid,
        course_code: 'databases',
        title: "Course #{title}",
        fixed_classifiers: [],
      })
    end
  end
end
