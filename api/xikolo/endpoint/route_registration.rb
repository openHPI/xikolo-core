# frozen_string_literal: true

module Xikolo
  module Endpoint
    class RouteRegistration
      def initialize(endpoint, handlers, routes)
        @endpoint = endpoint
        @handlers = handlers
        @routes = routes
      end

      def method_missing(http_method, description, &block)
        return super unless @endpoint.respond_to?(http_method)

        route = Xikolo::Endpoint::Route.new description, handler_for(http_method), block

        @routes[http_method] = route
        @endpoint.send http_method, &route
      end

      def respond_to_missing?(method, *)
        @endpoint.respond_to?(method)
      end

      private

      def handler_for(http_method)
        Xikolo::Versioning::Handler.new(
          @handlers.fetch(http_method),
          @endpoint.version_constraint
        )
      end
    end
  end
end
