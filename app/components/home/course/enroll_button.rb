# frozen_string_literal: true

module Home
  module Course
    class EnrollButton < ApplicationComponent
      def initialize(course, enrollment: nil, type: nil)
        @course = course
        @enrollment = enrollment
        @type = type
      end

      def call
        link_to(enrollment_link, class: css_classes, data:) do
          I18n.t(:'course.card.button_enroll')
        end
      end

      private

      def render?
        @enrollment.blank? && @course.self_service_enrollment?
      end

      def css_classes
        classes = %w[course-card__action-btn]
        classes << 'course-card__action-btn--large' if large?
        classes.join(' ')
      end

      def data
        return if @course.policy_url.blank?

        {
          toggle: 'modal',
          target: '#enrollmentPolicyModal',
          'course-code' => @course.course_code,
          'course-title' => @course.title,
          'policy-url' => Translations.new(@course.policy_url).to_s,
        }
      end

      def enrollment_link
        return '#' if @course.policy_url.present?

        enrollments_path(course_id: @course.course_code)
      end

      def large?
        @type == :large
      end
    end
  end
end
