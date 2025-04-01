# frozen_string_literal: true

module Bridges
  module Chatbot
    class CoursesController < BaseController
      before_action :require_valid_token!

      def index
        courses = []
        Xikolo.paginate(
          course_api.rel(:courses).get({hidden: false})
        ) do |course|
          next if course['invite_only']

          courses << serialize(course)
        end

        render json: courses
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
