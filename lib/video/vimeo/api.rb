# frozen_string_literal: true

require 'oauth2'
require 'json'

module Video
  module Vimeo
    class API
      def initialize(token, client_opts: {})
        @client = create_client(connection_opts: client_opts)
        @token = create_token @client, token
      end

      def get(url, params: {})
        response = @token.get url do |request|
          add_version_header(request)
          request.params.merge! params
        end

        JSON.parse response.body
      rescue OAuth2::Error => e
        raise ::Video::Provider::AuthenticationFailed if e.response.status == 401
        raise ::Video::Download::VideoNotAvailableError if e.response.status == 404

        raise RequestFailed.new(e.response.status)
      end

      def post(url, body: {})
        response = @token.post url do |request|
          add_version_header(request)
          request.body = body unless body.empty?
        end

        JSON.parse response.body
      end

      def patch(url, body: {})
        response = @token.patch url do |request|
          add_version_header(request)
          request.body = body unless body.empty?
        end

        JSON.parse response.body
      end

      def put(url, body: {})
        @token.put url do |request|
          add_version_header(request)
          request.body = body unless body.empty?
        end
      end

      def delete(url)
        @token.delete url do |request|
          add_version_header(request)
        end
      end

      private

      def create_token(client, token)
        OAuth2::AccessToken.new client, token
      end

      def create_client(client_id: '', client_secret: '', connection_opts: {})
        OAuth2::Client.new client_id,
          client_secret,
          site: 'https://api.vimeo.com',
          connection_opts:
      end

      def add_version_header(request)
        request.headers['Accept'] = 'application/vnd.vimeo.*+json;version=3.4'
      end

      class RequestFailed < ::RuntimeError
        def initialize(http_status)
          super("Request to Vimeo API failed with HTTP #{http_status}")
          @http_status = http_status
        end

        attr_reader :http_status
      end

      class RequestTimeout < ::RuntimeError
        def initialize(timeout)
          super("Request to Vimeo API failed due to timeout after #{timeout} seconds")
        end
      end
    end
  end
end
