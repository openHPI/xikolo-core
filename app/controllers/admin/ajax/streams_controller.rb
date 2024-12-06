# frozen_string_literal: true

module Admin
  module Ajax
    class StreamsController < Abstract::AjaxController
      # TODO: (XI-6286) add pagination (tomSelect supports this pretty easily, see https://tom-select.js.org/plugins/virtual_scroll/)

      def index
        authorize! 'video.video.index'

        streams = Video::Stream.includes(:provider).query(params[:q]).limit(250)

        render(
          json: streams.map do |stream|
            {
              id: stream.id,
              text: "#{stream.title} (#{stream.provider_name})",
            }
          end
        )
      end
    end
  end
end
