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
      # Check whether proctoring can be activated for a course by a user
      # This check describes rather formal criteria (proctoring activated for
      # the course) and not whether the user already has taken to many
      # assignments. The latter is handled by #upgrade_possible? to be able to
      # display more precise messages for the user.
      Proctoring.enabled? && # Proctoring enabled for the platform
        course_proctored? && # Proctoring enabled for the course
        !@enrollment.nil? && !@enrollment.proctored? # User has not enabled proctoring yet
    end

    # If the course has not started yet, or has been reactivated, the user can still upgrade to proctoring
    # and book a certificate.
    # Otherwise, we check proctoring feasibility for the started course, based
    # on the user's completed or missed assignments.
    def upgrade_possible?
      @upgrade_possible ||= !@course.was_available? || upgrade_regular_enrollment? || upgrade_when_reactivated?
    end

    def upgrading_deadline
      @upgrading_deadline ||= _upgrading_deadline
    end

    private

    def upgrade_regular_enrollment?
      !upgrading_deadline_passed? && bypassed_one_exam_only?
    end

    def upgrade_when_reactivated?
      currently_reactivated? && bypassed_one_exam_only?
    end

    def currently_reactivated?
      @course.offers_reactivation? && @enrollment.reactivated?
    end

    def course_proctored?
      !@course.nil? && @course.proctored?
    end

    def bypassed_one_exam_only?
      start = proctored_user_exams_promise

      # Fetch first page
      quizzes = start.value!

      # If there is only one proctored exam it must be completed with proctoring
      # and cannot be missed/skipped.
      return !taken_or_missed?(quizzes.first) if quizzes.count == 1

      # Else we want to allow upgrading to proctoring track unless the sum of a
      # user's missed assignments and submitted assignments is greater than one,
      # e.g. if the user joins in week 2 of a course.
      count = 0
      Xikolo.paginate(start) do |item|
        # Ignore items that haven't been available yet (was_available)
        next if item['start_date'].present? && ::DateTime.parse(item['start_date']).in_time_zone.future?

        count += 1 if taken_or_missed?(item)

        return false if count > 1
      end

      true
    end

    def taken_or_missed?(item)
      %w[submitted graded].include?(item['user_state']) || item_deadline_passed?(item)
    end

    def item_deadline_passed?(item)
      # If the course has been reactivated, don't care about the item submission
      # deadline but consider the reactivation status instead (forced submission date).
      return false if currently_reactivated?

      item['submission_deadline'].present? && ::DateTime.parse(item['submission_deadline']).in_time_zone.past?
    end

    def upgrading_deadline_passed?
      # The upgrading deadline is not present if no proctored exam exists.
      # In this case, a user can still upgrade to proctoring.
      upgrading_deadline&.past?
    end

    def _upgrading_deadline
      items = proctored_user_exams_promise.value!

      return _three_days_before(items.second['submission_deadline']) if items.second.present?

      _three_days_before(items.first['submission_deadline']) if items.first.present?
    end

    def _three_days_before(deadline)
      Date.parse(deadline) - 3.days
    end

    def proctored_user_exams_promise
      course_api.rel(:items).get(
        course_id: @course.id,
        content_type: 'quiz',
        exercise_type: 'main',
        proctored: true,
        published: true,
        state_for: @enrollment.user_id
      )
    end

    def course_api
      @course_api ||= Xikolo.api(:course).value!
    end
  end
end
