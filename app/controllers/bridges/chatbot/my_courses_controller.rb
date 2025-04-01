# frozen_string_literal: true

module Bridges
  module Chatbot
    class MyCoursesController < BaseController
      before_action :require_valid_token!

      def index
        courses = []
        Xikolo.paginate(
          course_api.rel(:courses).get({user_id: @user_id})
        ) do |course|
          courses << serialize(course)
        end
        render json: courses
      end

      def create
        course = course_api.rel(:course).get({id: params[:id]}).value!

        if course['invite_only']
          problem_details(
            'This course is invite-only.',
            status: :forbidden
          )
          return
        end

        # Create the new enrollment.
        course_api.rel(:enrollments).post({
          user_id: @user_id,
          course_id: params[:id],
        }).value!

        head(:ok)
      rescue Restify::ClientError => e
        problem_details(
          e.response.message,
          status: e.code
        )
      end

      def destroy
        enrollment = course_api.rel(:enrollments).get({
          course_id: params[:id], user_id: @user_id
        }).value!.first

        if enrollment.nil?
          problem_details(
            'The user is not enrolled for this course.',
            status: :not_found
          )
          return
        end

        course_api.rel(:enrollment).delete({id: enrollment['id']}).value!
      rescue Restify::ClientError => e
        problem_details(
          e.response.message,
          status: e.code
        )
      end

      private

      def serialize(course)
        {
          id: course['id'],
          title: course['title'],
          course_code: course['course_code'],
          start_date: course['start_date'],
          language: course['lang'],
          self_paced: course['status'] == 'archive',
          certificates: {
            roa: {
              enabled: course['roa_enabled'],
              requirement: course['roa_threshold_percentage'],
            },
            cop: {
              enabled: course['cop_enabled'],
              requirement: course['cop_threshold_percentage'],
            },
          },
        }
      end
    end
  end
end
