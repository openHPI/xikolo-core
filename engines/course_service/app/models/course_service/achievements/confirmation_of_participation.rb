# frozen_string_literal: true

module CourseService
class Achievements # rubocop:disable Layout/IndentationWidth
  class ConfirmationOfParticipation
    def initialize(course, evaluation)
      @course = course
      @evaluation = evaluation
    end

    def enabled?
      @course.cop_enabled
    end

    def achieved?
      enabled? && enrollment.present? && enough_visited?
    end

    def achieved_via_roa?
      # If a RoA has been achieved already, also the CoP is achieved.
      enabled? && enrollment.present? && roa.achieved?
    end

    def achievable?
      enabled? && enrollment.present? && !enough_visited? && !roa.achieved?
    end

    def released?
      @course.records_released?
    end

    private

    def enough_visited?
      return false if @evaluation.blank?

      @evaluation.visits_percentage >= @course.cop_threshold_percentage
    end

    def roa
      @roa ||= Achievements::RecordOfAchievement.new @course, @evaluation
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
