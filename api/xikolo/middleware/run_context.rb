# frozen_string_literal: true

require 'rack/request'

module Xikolo
  module Middleware
    class RunContext
      def initialize(env)
        @env = env
        @request = Rack::Request.new @env

        @env['xikolo.api.document'] = Xikolo::JSONAPI::Document.new(self)
      end

      attr_reader :env, :request

      def headers
        @headers ||= @env
          .select {|k, _| k.start_with? 'HTTP_' }
          .transform_keys {|k| k.sub(/^HTTP_/, '').downcase }
      end

      def query
        @env['rack.request.query_hash'] || {}
      end

      def id
        @env['grape.routing_args'].fetch :id
      end

      def filters
        @env['xikolo.api.request.filters'] || {}
      end

      def includes
        query['include'].to_s.split ','
      end

      def sort_fields
        query['sort'].to_s.split ','
      end

      def document
        @env['xikolo.api.document']
      end

      def remote_addr
        # Give preference to the value determined by Rails' Remote IP
        # middleware, if available.
        (@env['action_dispatch.remote_ip'] || @request.ip).to_s
      end

      def current_user
        @current_user ||= _create_user
      end

      def accept_language
        headers['accept_language']&.to_sym
      end

      # Sets a global context for permissions
      def in_context(context_name)
        @context = context_name

        # Just in case it has been requested before, we throw away the
        # current user object, so that it will be regenerated when
        # it is requested again.
        @current_user = nil
      end

      def authenticate!
        unauthorized! if current_user.anonymous?
      end

      def authenticate_as!(user_id)
        authenticate!
        forbidden! unless current_user.id.eql? user_id
      end

      def permission!(permission)
        forbidden! unless current_user.allowed?(permission)
      end

      def any_permission!(*)
        forbidden! unless current_user.allowed_any?(*)
      end

      def unauthorized!
        raise Xikolo::Error::Unauthorized.new 401, '401 Unauthorized'
      end

      def forbidden!
        raise Xikolo::Error::Unauthorized.new 403, '403 Forbidden'
      end

      def not_found!(message = '')
        raise Xikolo::Error::NotFound.new message
      end

      def exec(block)
        params = @env['xikolo.api.request.body.parsed'] || {}
        result = instance_exec params, &block

        result = Restify::Promise.fulfilled result unless result.is_a? Restify::Promise

        result
      rescue ::Restify::Unauthorized
        unauthorized!
      rescue ::Restify::NotFound
        not_found!
      end

      def sub_request(block, parsed_body:)
        SubRequestContext.new(
          self, {'xikolo.api.request.body.parsed' => parsed_body}
        ).exec(block)
      end

      def cached_sub_request(route, **opts)
        sub_request_cache[route][opts] ||= SubRequestContext.new(
          self, {}, **opts
        ).exec(route.block)
      end

      # Return a string to be used in the HTTP Authorization header for requests to internal services
      def auth_header
        if @env['XIKOLO_LEGACY_TOKEN']
          "Legacy-Token token=#{@env['XIKOLO_LEGACY_TOKEN']}"
        elsif @env['XIKOLO_SESSION']
          "Xikolo-Session session_id=#{@env['XIKOLO_SESSION']}"
        else
          'anonymous'
        end
      end

      def block_courses_by(filter_field, &block)
        response = yield block
        response.tap do |r| # exclude those elements referring to courses on a blocked list from being visible via the API
          r.reject! {|item| blocked?(item[filter_field]) }
        end
      end

      def block_access_by(filter_field, &block)
        response = yield block
        not_found! if blocked?(response[filter_field])
        response
      end

      private

      def blocked?(course_id)
        # We must not block ember requests, since the web app won't work otherwise
        app_request? && Xikolo.config.api&.fetch('blocked_course_ids', [])&.include?(course_id)
      end

      def app_request?
        # This is similar to `Abstract::FrontendController#check_app_request`
        (request.get_header('HTTP_ACCEPT') == 'application/vnd.xikolo.v1, application/json') ||
          request.has_header?('HTTP_USER_PLATFORM') ||
          request.has_header?('HTTP_X_USER_PLATFORM') ||
          (request.cookies['in_app'] == '1')
      end

      def sub_request_cache
        @sub_request_cache ||= Hash.new {|h, k| h[k] = {} }
      end

      def _create_user
        Xikolo::Common::Auth::CurrentUser.from_session _load_session_object
      end

      def _load_session_object
        Xikolo.api(:account).value!.rel(:session).get({
          id: _session_id,
          embed: 'user,permissions,features',
          context: _current_context,
        }).value!
      rescue Restify::NotFound # Session has expired
        unauthorized!
      end

      def _session_id
        if @env['XIKOLO_SESSION']
          @env['XIKOLO_SESSION']
        elsif @env['XIKOLO_LEGACY_TOKEN']
          "token=#{@env['XIKOLO_LEGACY_TOKEN']}"
        else
          'anonymous'
        end
      end

      def _current_context
        @context || 'root'
      end

      # The context for a sub request (e.g. when sideloading related data)
      class SubRequestContext
        def initialize(context, env, **opts)
          @context = context
          @additional_env = env
          @opts = opts
        end

        # Delegate the request-global methods to the decorated context object
        extend Forwardable
        def_delegators :@context,
          :request, :document, :remote_addr, :current_user, :in_context,
          :authenticate!, :authenticate_as!, :permission!, :any_permission!,
          :unauthorized!, :forbidden!, :not_found!, :sub_request,
          :cached_sub_request, :auth_header, :headers, :accept_language,
          :block_courses_by, :block_access_by

        def env
          @env ||= @context.env.merge(@additional_env)
        end

        def id
          @opts.fetch :id
        end

        def query
          @opts[:filters] ? {'filter' => @opts[:filters]} : {}
        end

        def filters
          @opts.fetch :filters, {}
        end

        def includes
          []
        end

        def sort_fields
          []
        end

        def exec(block)
          params = env['xikolo.api.request.body.parsed'] || {}
          result = instance_exec params, &block

          result = Restify::Promise.fulfilled result unless result.is_a? Restify::Promise

          result
        end
      end
    end
  end
end
