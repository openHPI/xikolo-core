# frozen_string_literal: true

require 'rack/auth/abstract/handler'

module Xikolo
  module Auth
    module Middleware
      class Session < Rack::Auth::AbstractHandler
        def call(env)
          env['XIKOLO_SESSION'] = session(env)[:id]

          @app.call(env)
        end

        private

        def session(env)
          env['rack.session'] || {}
        end
      end
    end
  end
end
