# frozen_string_literal: true

module CourseService
class Achievements # rubocop:disable Layout/IndentationWidth
  class RecordOfAchievement
    def initialize(course, evaluation)
      @course = course
      @evaluation = evaluation
    end

    def enabled?
      @course.roa_enabled
    end

    def achieved?
      enabled? && enrollment.present? && enough_points?
    end

    def achievable?
      enabled? && enrollment.present? && !enough_points? && !@course.ended?
    end

    def released?
      @course.records_released?
    end

    private

    def enough_points?
      return false if @evaluation.blank?

      @evaluation.points_percentage >= @course.roa_threshold_percentage
    end

    # Ensure that this is an `Enrollment` instance no matter if a dynamic
    # or persisted learning evaluation has been passed in.
    def enrollment
      @enrollment ||= if @evaluation.present?
                        @course.enrollments.find_by(user_id: @evaluation.user_id)
                      end
    end
  end
end
end
