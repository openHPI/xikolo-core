# frozen_string_literal: true

module Course
  class Statistics
    # @param course [CourseService::Course]
    def initialize(course)
      @course = course
    end

    # The number of users who enrolled in the course and visited at least
    # one item by the middle of the course.
    #
    # If the course middle is in the future, we cannot determine the shows
    # and explicitly return `nil`.
    def shows_at_middle
      return unless @course.middle_of_course&.past?

      shows_at(@course.middle_of_course, course: @course)
    end

    def completion_rate
      percent(roa_count, shows_at_middle)
    end

    def cop_count
      certificates.fetch('ConfirmationOfParticipation', 0)
    end

    def roa_count
      certificates.fetch('RecordOfAchievement', 0)
    end

    def enrollments
      @enrollments ||= ::Course::EnrollmentsStatistics.new(course: @course)
    end

    private

    # @param date [ActiveSupport::TimeWithZone]
    # @param course [CourseService::Course]
    def shows_at(date, course:)
      shows = ::CourseService::Visit.where(item: course.items.unscope(:order).select(:id))
      shows = shows.where(created_at: ..date) if date
      shows.distinct.count(:user_id) + course.enrollment_delta
    end

    def percent(count, total)
      return 0 unless total&.positive?

      (count * 100).fdiv(total).floor
    end

    def certificates
      Certificate::Record.where(course_id: @course.id).group(:type).count
    end
  end
end
