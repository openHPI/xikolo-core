# frozen_string_literal: true

module Home
  module Course
    class ExternalButton < ApplicationComponent
      def initialize(course)
        @course = course
      end

      private

      def render?
        @course.external?
      end
    end
  end
end
