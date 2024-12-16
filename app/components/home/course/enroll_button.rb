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
        link_to(enrollments_path(course_id: @course.course_code), class: css_classes) do
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

      def large?
        @type == :large
      end
    end
  end
end
