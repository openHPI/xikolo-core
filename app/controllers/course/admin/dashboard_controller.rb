# frozen_string_literal: true

module Course
  module Admin
    class DashboardController < Abstract::FrontendController
      include CourseContextHelper

      before_action :set_no_cache_headers

      inside_course

      def show
        authorize! 'course.dashboard.view'

        @course = the_course
        Acfs.run # wait for course context promises
      end

      def hide_course_nav?
        true
      end

      private

      def auth_context
        the_course.context_id
      end

      # fix course receiving
      def request_course
        Xikolo::Course::Course.find(params[:id])
      end
    end
  end
end
