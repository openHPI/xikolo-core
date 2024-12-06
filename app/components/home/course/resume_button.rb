# frozen_string_literal: true

module Home
  module Course
    class ResumeButton < ApplicationComponent
      def initialize(course, enrollment: nil, type: nil)
        @course = course
        @enrollment = enrollment
        @type = type
      end

      def css_classes
        classes = %w[course-card__action-btn]
        classes << 'course-card__action-btn--large' if large?
        classes.join(' ')
      end

      private

      def render?
        @enrollment.present?
      end

      def large?
        @type == :large
      end
    end
  end
end
