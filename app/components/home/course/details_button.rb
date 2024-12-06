# frozen_string_literal: true

module Home
  module Course
    class DetailsButton < ApplicationComponent
      def initialize(course, type: nil)
        @course = course
        @type = type
      end

      def call
        link_to course_path(@course.course_code), class: css_classes do
          I18n.t(:'course.card.button_details')
        end
      end

      def css_classes
        classes = %w[course-card__action-btn course-card__action-btn--tertiary]
        classes << 'course-card__action-btn--large' if large?
        classes.join(' ')
      end

      def large?
        @type == :large
      end
    end
  end
end
