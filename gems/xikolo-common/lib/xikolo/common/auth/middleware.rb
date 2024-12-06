# frozen_string_literal: true

require 'xikolo/common/auth/current_user'

module Xikolo
  module Common
    module Auth
      class Middleware
        TOKEN_AUTH_REGEX = /^(Legacy-)?Token token=(?<token>[0-9a-f]+)$/ # rubocop:disable Lint/MixedRegexpCaptureTypes
        SESSION_ID_REGEX = /^Xikolo-Session session_id=(?<session_id>[-0-9a-fA-F]+)$/

        def initialize(app, path: '/')
          @app = app
          @path = path
        end

        def call(env)
          env['current_user'] = current_user_promise(env) if env['PATH_INFO'].to_s.start_with? @path

          @app.call(env)
        end

        def current_user_promise(env)
          Xikolo.api(:account).value!.rel(:session).get(
            id: session_id(env),
            embed: 'user,permissions,features',
            context: context_id(env)
          ).then do |session|
            Xikolo::Common::Auth::CurrentUser.from_session session
          end
        end

        private

        def session_id(env)
          if env['rack.session'] && env['rack.session'][:id]
            env['rack.session'][:id]
          elsif (match = SESSION_ID_REGEX.match(env['HTTP_AUTHORIZATION']))
            match[:session_id]
          elsif (match = TOKEN_AUTH_REGEX.match(env['HTTP_AUTHORIZATION']))
            "token=#{match[:token]}"
          else
            'anonymous'
          end
        end

        def context_id(env)
          return env['xikolo_context'].value! if env['xikolo_context'].respond_to?(:value!)
          return env['xikolo_context'] if env['xikolo_context']

          'root'
        end
      end
    end
  end
end
