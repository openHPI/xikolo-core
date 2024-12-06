# frozen_string_literal: true

require 'kaltura'
require 'digest'

module Video
  module KalturaIntegration
    class API
      def initialize(credentials)
        @credentials = credentials
      end

      def client
        @client ||= Kaltura::KalturaClient.new(client_config).tap do |client|
          # A widget session (ie. with no privileges) must be started first to create a ks param.
          # After starting each session (both widget and privileged), the client must set the ks
          # in its request configuration to be able to call and query Kaltura services.
          widget_session = client.session_service.start_widget_session(widget_id)
          client.set_ks(widget_session.ks)

          # With a widget session and the ks set, a privileged session can be started.
          # Required params are: id of the token, hash of the token. The user ID (last parameter)
          # should already be enforced by the token and does not need to be sent again here.
          privileged_session = client.app_token_service.start_session(token_id, hash(widget_session), '')
          client.set_ks(privileged_session.ks)
        end
      end

      private

      def client_config
        Kaltura::KalturaConfiguration.new.tap do |config|
          config.service_url = Xikolo.config.kaltura['api_url']
        end
      end

      def widget_id
        "_#{@credentials['partner_id']}"
      end

      def token_id
        @credentials['token_id']
      end

      def hash(widget_session)
        Digest::SHA256.hexdigest(widget_session.ks + @credentials['token'])
      end
    end
  end
end
