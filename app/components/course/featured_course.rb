# frozen_string_literal: true

module Course
  class FeaturedCourse < ApplicationComponent
    def initialize(course, enrollment: nil)
      @course = course
      @enrollment = enrollment
    end

    def course_visual
      ::Course::CourseVisual.new(
        @course.visual&.image_url,
        css_classes: 'featured-course__image'
      )
    end

    def course_abstract
      Rails::HTML5::SafeListSanitizer.new.sanitize(helpers.render_markdown(@course.abstract), tags: %w[p br])
    end
  end
end
