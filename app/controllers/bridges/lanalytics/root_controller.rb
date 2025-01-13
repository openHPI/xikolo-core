# frozen_string_literal: true

module Bridges
  module Lanalytics
    class RootController < BaseController
      respond_to :json

      def index
        respond_with({
          course_open_badge_stats_url: bridges_lanalytics_course_open_badge_stats_rfc6570,
          course_ticket_stats_url: bridges_lanalytics_course_ticket_stats_rfc6570,
          video_stats_url: bridges_lanalytics_video_stats_rfc6570,
        })
      end
    end
  end
end
