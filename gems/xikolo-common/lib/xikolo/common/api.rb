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
        application/msgpack
        application/x-msgpack
        application/json
      ].join(', ').freeze

      def services
        @services ||= {}
      end

      def [](name)
        ::Restify.new(
          services.fetch(name),
          headers: {'Accept' => ACCEPT_HEADER}
        ).get
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
