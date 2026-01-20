# frozen_string_literal: true

require 'restify'

module Xikolo::Common
  module API
    class ServiceNotConfigured < KeyError
      attr_reader :service

      def initialize(name)
        @service = name
        super("Service '#{name}' is unknown. You can register it with `Stub.service(:#{name}, {})`.")
      end
    end

    class << self
      ACCEPT_HEADER = %w[
        application/json
      ].join(', ').freeze

      def services
        @services ||= {}
      end

      def authorized_request(url)
        ::Restify.new(
          url,
          headers: {
            'Accept' => ACCEPT_HEADER,
            'Authorization' => "Bearer #{ENV.fetch('XIKOLO_WEB_API')}",
          }
        )
      end

      def [](name)
        authorized_request(services.fetch(name)).get
      rescue KeyError
        raise ServiceNotConfigured.new(name)
      end

      def assign(name, url)
        services[name.to_sym] = url
      end
    end

    def api(name)
      ::Xikolo::Common::API[name]
    end

    def api?(name)
      ::Xikolo::Common::API.services.key? name
    end
  end

  ::Xikolo.extend API
end
