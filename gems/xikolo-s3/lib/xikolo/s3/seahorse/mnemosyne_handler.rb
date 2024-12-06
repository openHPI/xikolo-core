# frozen_string_literal: true

module Xikolo::S3
  module Seahorse
    class MnemosyneHandler < ::Seahorse::Client::Handler
      # @param [RequestContext] context
      # @return [Response]
      def call(context)
        trace = ::Mnemosyne::Instrumenter.current_trace

        return @handler.call(context) unless trace

        req = context.http_request
        span = ::Mnemosyne::Span.new 'external.http.seahorse',
          meta: {
            url: req.endpoint.to_s,
            method: req.http_method.downcase.to_sym,
          }

        span.start!

        @handler.call(context).tap do |response|
          res = response.context.http_response
          span.meta[:status] = res.status_code

          trace << span.finish!
        end
      end
    end
  end
end
