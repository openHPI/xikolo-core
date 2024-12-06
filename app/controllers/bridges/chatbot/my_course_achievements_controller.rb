# frozen_string_literal: true

module Bridges
  module Chatbot
    class MyCourseAchievementsController < BaseController
      before_action :require_valid_token!

      def show
        render json: {certificates:, points:, visits:}
      end

      private

      def achievements
        @achievements ||= course.rel(:achievements).get(
          {user_id: @user_id},
          {headers: {'Accept-Language' => request.headers['Accept-Language']}}
        ).value!
      end

      def certificates
        achievements.map {|achievement| serialize(achievement) }
      end

      def serialize(achievement)
        achievement.slice('type', 'name', 'description', 'achieved', 'achievable', 'requirements', 'download')
      end

      def points
        achievements.find {|k| k['points'] }['points']
      end

      def visits
        achievements.find {|k| k['visits'] }['visits']
      end

      def course
        @course ||= course_api.rel(:course).get(id: params[:id]).value!
      end
    end
  end
end
