# frozen_string_literal: true

module Bridges
  module Lanalytics
    class CourseOpenBadgeStatsController < BaseController
      respond_to :json

      def show
        respond_with({
          badges_issued: Certificate::OpenBadge.issue_count(params[:course_id]).to_i,
        })
      end
    end
  end
end
