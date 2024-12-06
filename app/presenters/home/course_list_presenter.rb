# frozen_string_literal: true

module Home
  class CourseListPresenter
    def initialize(courses)
      @courses = courses
    end

    def courses_count
      @courses.length
    end
  end
end
