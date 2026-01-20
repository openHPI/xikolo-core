# frozen_string_literal: true

require 'singleton'

module Xikolo
  module V2
    class URL
      include Singleton

      class << self
        def method_missing(name, *, **)
          if instance.respond_to?(name)
            instance.public_send(name, *, **)
          else
            super
          end
        end

        def respond_to_missing?(name, *)
          instance.respond_to?(name)
        end
      end

      include Rails.application.routes.url_helpers

      extend Forwardable

      def default_url_options
        {host:, port:, protocol:}
      end

      def host
        Xikolo.base_url.host
      end

      def port
        Xikolo.base_url.port
      end

      def protocol
        Xikolo.base_url.scheme
      end

      # Don't raise exceptions when an asset cannot be found, but instead
      # assume it is in the /public folder.
      def unknown_asset_fallback
        true
      end

      def asset_url(path)
        ActionController::Base.helpers.asset_url(path)
      end
    end
  end
end
