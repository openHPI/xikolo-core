# frozen_string_literal: true

module Admin
  module Ajax
    class CoursesController < Abstract::AjaxController
      respond_to :json

      before_action :ensure_logged_in

      def index
        authorize_any! 'course.course.index', 'course.document.manage'

        courses = course_api.rel(:courses).get(
          autocomplete: params[:q],
          offset: params[:offset],
          limit: 50
        ).value!

        render json: courses.map {|c| {id: c['id'], text: "#{c['title']} (#{c['course_code']})"} }
      end

      private

      def course_api
        @course_api ||= Xikolo.api(:course).value!
      end
    end
  end
end
