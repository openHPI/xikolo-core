# frozen_string_literal: true

module Course
  class EnrollmentStatistics < ApplicationComponent
    MIN_ENROLLMENTS = 500

    def initialize(course, user:)
      @course = course
      @user = user
      @stats = ::Course::Course.find(@course.id).stats.enrollments
    end

    def enrollment_statistics
      return unless @course.end_date&.past?

      @enrollment_statistics ||= [].tap do |stats|
        stats << {
          type: 'current',
          count: readable_count(@stats.current),
          date: I18n.t(:'course.courses.enrollment_statistics.current.date'),
        }
        if @stats.at_end.present?
          stats << {
            type: 'course_end',
            count: readable_count(@stats.at_end),
            date: I18n.l(@course.end_date.in_time_zone.to_date, format: :short),
          }
        end
        if @stats.at_start.present?
          stats << {
            type: 'course_start',
            count: readable_count(@stats.at_start),
            date: I18n.l(@course.effective_start_date.in_time_zone.to_date, format: :short),
          }
        end
      end
    end

    def enrollment_count
      return unless display_enrollment_count?

      @stats.current
    end

    def display_enrollment_count?
      surpassed_min_enrollments? || @user.allowed?('course.enrollment_counter.view')
    end

    private

    def surpassed_min_enrollments?
      !@course.external? && (@stats.current >= MIN_ENROLLMENTS)
    end

    def readable_count(count)
      number_with_delimiter(count)
    end
  end
end
