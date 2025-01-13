# frozen_string_literal: true

module Bridges
  module Lanalytics
    class VideoStatsController < BaseController
      respond_to :json

      def show
        video = Video::Video.find(params[:video_id])

        respond_with({duration: video.duration})
      rescue ActiveRecord::RecordNotFound
        render json: {}, status: :not_found
      end
    end
  end
end
