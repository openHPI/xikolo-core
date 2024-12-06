# frozen_string_literal: true

module Xi
  module Controllers
    class RequireBearerToken
      def initialize(token:, realm:)
        @token = token
        @realm = realm
      end

      def before(controller)
        # Missing Authorization header?
        if controller.request.headers['HTTP_AUTHORIZATION'].blank?
          controller.response.headers['WWW-Authenticate'] = "Bearer realm=\"#{@realm}\""

          return controller.render problem_details(
            'https://tools.ietf.org/html/rfc6750#section-3',
            'You must provide an Authorization header to access this resource.',
            status: :unauthorized
          )
        end

        # Correct shared secret?
        if controller.request.headers['HTTP_AUTHORIZATION'] != "Bearer #{@token.call}"
          controller.response.headers['WWW-Authenticate'] = "Bearer realm=\"#{@realm}\", error=\"invalid_token\""

          controller.render problem_details(
            'https://tools.ietf.org/html/rfc6750#section-3.1',
            'The bearer token you provided was invalid, has expired or has been revoked.',
            status: :unauthorized
          )
        end
      end

      private

      def problem_details(documentation_url, title, status:, **render_opts)
        {
          content_type: 'application/problem+json',
          json: {
            type: documentation_url,
            title:,
            status: Rack::Utils.status_code(status),
          },
          status:,
          **render_opts,
        }
      end
    end
  end
end
