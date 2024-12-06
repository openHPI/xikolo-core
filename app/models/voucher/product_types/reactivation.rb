# frozen_string_literal: true

module Voucher
  module ProductTypes
    class Reactivation
      class << self
        def enabled?
          ::CourseReactivation.enabled?
        end

        # Check platform and course settings: Is reactivation enabled?
        # @param course [Course::Course]
        def enabled_in?(course)
          return false unless enabled?
          return false unless course.offers_reactivation?
          # Is it too early for reactivation?
          return false if course.start_date&.future? ||
                          course.end_date&.future? ||
                          course.status == 'preparation'

          true
        end

        def type
          'course_reactivation'
        end

        def text
          I18n.t(:'course.redeem_voucher.course_reactivation.text',
            weeks: ::CourseReactivation.config('period'),
            link: ::CourseReactivation.store_url)
        end

        def info_text
          I18n.t(:'course.redeem_voucher.course_reactivation.info_text', link: ::CourseReactivation.store_url)
        end

        def unavailable_message
          I18n.t(:'flash.error.reactivation.not_available')
        end
      end

      def initialize(course, user)
        @course = course
        @user = user
      end

      # Is reactivation allowed for the user?
      def valid?
        if !@user.feature?('course_reactivation')
          @error = I18n.t(:'flash.error.reactivation.not_available')
        elsif enrollment&.reactivated?
          @error = I18n.t(:'flash.error.reactivation.already_reactivated')
        end

        @error.blank?
      end

      attr_reader :error

      def success_message
        new_deadline = enrollment.forced_submission_date
        I18n.t(:'flash.success.reactivate_course', date: I18n.l(new_deadline, format: :long))
      end

      def claim!
        submission_date = Time.zone.now + ::CourseReactivation.config('period').weeks

        Xikolo.api(:course).value!
          .rel(:enrollments)
          .post(course_id: @course.id, user_id: @user.id)
          .value!
          .rel(:reactivations)
          .post(submission_date: submission_date.iso8601)
          .value!
      end

      private

      def enrollment
        # Intentionally not memoized, as the enrollment may not exist before reactivation.
        # Also, we need to truly reload it anyway to display the new deadline upon success.
        Course::Enrollment.uncached do
          @course.enrollments.find_by(user_id: @user.id)
        end
      end
    end
  end
end
