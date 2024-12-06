# frozen_string_literal: true

module Home
  module Course
    class ReactivationButton < ApplicationComponent
      def initialize(course, user:, enrollment: nil, style: 'button')
        @course = course
        @user = user
        @enrollment = enrollment
        @style = style
      end

      private

      def css_classes
        if @style == 'button'
          'course-card__action-btn course-card__action-btn--secondary'
        end
      end
    end
  end
end
