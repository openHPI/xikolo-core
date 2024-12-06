# frozen_string_literal: true

require 'rack/request'
require 'uuid4'

module Middleware
  class NewsTracker
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new env

      if news_tracking_info? request
        announcement = UUID4.try_convert request.params['tracking_id']
        user = UUID4.try_convert request.params['tracking_user']

        mark_as_read! announcement, user if announcement && user
      end

      @app.call env
    end

    private

    def news_tracking_info?(request)
      request.params['tracking_type'] == 'news' && %w[tracking_user tracking_id].all? {|key| request.params.key? key }
    end

    def mark_as_read!(announcement_id, user_id)
      # Send the request to mark the announcement as read for the given user.
      #
      # NOTE: We're not calling `value` here, so that the request is executed in parallel
      # while the actual application is run. Also, this way we do not delay sending of the
      # response in case the news service is hanging or taking a long time to respond.
      Xikolo.api(:news).value!.rel(:visits).post(
        user_id:,
        announcement_id: announcement_id.to_s
      )
    end
  end
end
