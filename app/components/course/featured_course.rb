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
  end
end
