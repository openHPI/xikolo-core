# frozen_string_literal: true

module Bridges
  module Transpipe
    class VideosController < BaseController
      before_action Xi::Controllers::RequireBearerToken.new(
        realm: Transpipe.realm,
        token: -> { Transpipe.shared_secret }
      )

      def show
        render json: serialize_video(Video::Video.find(params[:id]))
      rescue ActiveRecord::RecordNotFound
        head(:not_found, content_type: 'text/plain')
      end

      private

      def course_id
        @course_id ||= Course::Item.find_by(content_id: params[:id])&.section&.course_id
      end

      def serialize_video(video)
        {
          id: video.id,
          'course-id' => course_id,
          summary: video.description&.external,
          subtitles: video.subtitles.map {|subtitle| serialize_subtitle(subtitle) },
          streams: {
            pip: serialize_stream(video.pip_stream),
            lecturer: serialize_stream(video.lecturer_stream),
            slides: serialize_stream(video.slides_stream),
          },
        }
      end

      def serialize_subtitle(subtitle)
        {
          language: subtitle.lang,
          automatic: subtitle.automatic,
        }
      end

      def serialize_stream(stream)
        {
          hd: stream&.hd_url,
          sd: stream&.sd_url,
          hls: stream&.hls_url,
        }
      end
    end
  end
end
