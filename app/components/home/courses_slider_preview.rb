# frozen_string_literal: true

module Home
  class CoursesSliderPreview < ViewComponent::Preview
    def default
      render Home::CoursesSlider.new(courses, href: '/', title: 'Latest courses')
    end

    def light
      render Home::CoursesSlider.new(courses, href: '/', title: 'Latest courses', slider_variant: :light)
    end

    private

    COURSE_ID = SecureRandom.uuid

    def courses
      Array.new(10, course)
    end

    def course
      Catalog::Course.new({
        id: COURSE_ID,
        course_code: 'databases',
        title: 'Everything about databases',
        teacher_text: 'Prof. D. B. Expert',
        abstract: 'Tables, rows and columns; all day long',
        start_date: 2.weeks.ago,
        end_date: 3.weeks.from_now,
        lang: 'en',
        fixed_classifiers: [],
        roa_enabled: true,
      })
    end
  end
end
