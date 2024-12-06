# frozen_string_literal: true

module Bridges
  module Transpipe
    class SubtitlesController < BaseController
      before_action Xi::Controllers::RequireBearerToken.new(
        realm: Transpipe.realm,
        token: -> { Transpipe.shared_secret }
      )

      def show
        render plain: subtitle.to_vtt, content_type: 'text/vtt'
      rescue ActiveRecord::RecordNotFound
        render plain: '', status: :not_found, content_type: 'text/vtt'
      end

      def update
        return problem_details('The request body cannot be blank.', status: :bad_request) if request.raw_post.blank?

        vtt = request.raw_post.force_encoding('UTF-8')
        video = ::Video::Video.find params[:id]
        automatic = params.fetch(:automatic, false)
        ::Video::Subtitle.attach!(vtt, params[:lang], video, automatic:)

        head(:ok)
      rescue ActiveRecord::RecordNotFound
        head(:not_found)
      rescue ActiveRecord::RecordInvalid
        head(:unprocessable_entity)
      rescue WebVTT::MalformedFile
        head(:bad_request)
      rescue ::Video::InvalidSubtitleError => e
        problem_details(
          I18n.t(
            "items.video.errors.#{e.message}",
            count: e.identifiers.length,
            identifiers: e.identifiers.join(', ')
          ),
          status: :unprocessable_entity
        )
      end

      private

      def subtitle
        @subtitle ||= ::Video::Video.find(params[:id]).subtitles
          .find_by!(lang: params[:lang])
      end
    end
  end
end
