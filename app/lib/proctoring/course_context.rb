# frozen_string_literal: true

module Proctoring
  class CourseContext
    # @param course [Xikolo::Course::Course|Course::Course|Restify::Resource]
    # @param enrollment [Xikolo::Course::Enrollment|Course::Enrollment|Restify::Resource]
    def initialize(course, enrollment)
      @course = course
      @enrollment = enrollment
    end

    def enabled?
      # Check whether proctoring has been activated for a course by a user
      Proctoring.enabled? &&
        course_proctored? &&
        !@enrollment.nil? && @enrollment.proctored?
    end

    def can_enable?
      # Check whether proctoring can be activated for a course by a user.
      # This check describes rather formal criteria (proctoring activated for
      # the course) and not whether the user already has taken to many
      # assignments. The latter is handled by #upgrade_possible? to be able to
      # display more precise messages for the user.
      Proctoring.enabled? && # Proctoring enabled for the platform
        course_proctored? && # Proctoring enabled for the course
        !@enrollment.nil? && !@enrollment.proctored? # User has not enabled proctoring yet
    end

    # Temporary: We do not allow enabling proctoring for now.
    def upgrade_possible?
      false
    end

    private

    def course_proctored?
      !@course.nil? && @course.proctored?
    end
  end
end
