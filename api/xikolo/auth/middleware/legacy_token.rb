# frozen_string_literal: true

require 'rack/auth/abstract/handler'

module Xikolo
  module Auth
    module Middleware
      class LegacyToken < Rack::Auth::AbstractHandler
        TOKEN_AUTH_REGEX = /^(?:Legacy-)?Token token=(?<token>[0-9a-f]+)$/

        def call(env)
          if (match = TOKEN_AUTH_REGEX.match(env['HTTP_AUTHORIZATION']))
            env['XIKOLO_LEGACY_TOKEN'] = match[:token]
          end

          @app.call(env)
        end
      end
    end
  end
end
