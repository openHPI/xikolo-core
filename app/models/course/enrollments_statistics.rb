# frozen_string_literal: true

module Course
  class EnrollmentsStatistics
    # @param course [CourseService::Course]
    def initialize(course:)
      @course = course
      @enrollments = course.enrollments.unscope(:order)
    end

    def current
      @enrollments.count + @course.enrollment_delta
    end
  end
end
