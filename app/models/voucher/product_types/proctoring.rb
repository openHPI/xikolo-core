# frozen_string_literal: true

module Voucher
  module ProductTypes
    class Proctoring
      class << self
        def enabled?
          ::Proctoring.enabled?
        end

        # Check platform and course settings: Is proctoring enabled?
        # @param course [Course::Course]
        def enabled_in?(course)
          return false unless enabled?
          return false unless course.proctored?

          true
        end

        def type
          'proctoring_smowl'
        end

        def text
          I18n.t(:'course.redeem_voucher.proctoring_smowl.text')
        end

        def info_text
          I18n.t(
            :'course.redeem_voucher.proctoring_smowl.info_text',
            link: ::Proctoring.store_url,
            brand: Xikolo.config.site_name
          )
        end

        def unavailable_message
          I18n.t(:'flash.error.proctoring.booking_failed')
        end
      end

      def initialize(course, user)
        @course = course
        @user = user
      end

      # Is proctoring allowed for the user?
      def valid?
        enrollment = @course.enrollments.active.find_by(user_id: @user.id)

        if enrollment.blank?
          @error = I18n.t(:'flash.error.proctoring.not_enrolled')
        elsif enrollment.proctored?
          @error = I18n.t(:'flash.error.proctoring.already_proctored')
        elsif !::Proctoring::CourseContext.new(@course, enrollment).upgrade_possible?
          @error = I18n.t(:'flash.error.proctoring.booking_failed')
        end

        @error.blank?
      end

      attr_reader :error

      def success_message
        I18n.t(:'flash.success.proctoring.certificate_booked')
      end

      def claim!
        Xikolo.api(:course).value!
          .rel(:enrollments)
          .post(course_id: @course.id, user_id: @user.id, proctored: true)
          .value!
      end
    end
  end
end
