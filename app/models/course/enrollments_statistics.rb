# frozen_string_literal: true

module Course
  class EnrollmentsStatistics
    # @param course [Course::Course]
    def initialize(course:)
      @course = course
      @enrollments = course.enrollments.unscope(:order)
    end

    def current
      @enrollments.count + @course.enrollment_delta
    end

    def at_start
      return unless @course.start_date&.past?

      enrollments = created_by(@enrollments, date: @course.start_date)
      enrollments.count + @course.enrollment_delta
    end

    def at_end
      return unless @course.end_date&.past?

      enrollments = created_by(@enrollments, date: @course.end_date)
      enrollments.count + @course.enrollment_delta
    end

    private

    def created_by(scope, date:)
      scope.where(created_at: ..date)
    end
  end
end
