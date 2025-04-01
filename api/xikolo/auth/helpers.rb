# frozen_string_literal: true

module Xikolo
  module Auth
    module Helpers
      def current_user
        @current_user ||= _create_user
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
        error!('401 Unauthorized', 401) if current_user.anonymous?
      end

      def authenticate_as!(user_id)
        authenticate!
        error!('403 Forbidden', 403) unless current_user.id.eql? user_id
      end

      def permission!(permission)
        error!('401 Unauthorized', 401) unless current_user.allowed?(permission)
      end

      def _session_id
        if env['XIKOLO_SESSION']
          env['XIKOLO_SESSION']
        elsif env['XIKOLO_LEGACY_TOKEN']
          "token=#{env['XIKOLO_LEGACY_TOKEN']}"
        else
          'anonymous'
        end
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
      rescue Restify::ClientError => e
        raise e unless e.status == 404
      end

      def _current_context
        @context || 'root'
      end
    end
  end
end
