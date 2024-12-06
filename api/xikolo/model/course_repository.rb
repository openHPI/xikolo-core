# frozen_string_literal: true

module Xikolo
  module Model
    class CourseRepository
      def courses_for(user, course_id)
        courses = course_api.rel(:courses).get(
          per_page: 100,
          user_id: user.id
        ).value!
        if course_id.present?
          courses.select {|c| c['id'] == course_id }
        else
          courses
        end
      end

      private

      def course_api
        @course_api ||= Xikolo.api(:course).value!
      end
    end
  end
end
