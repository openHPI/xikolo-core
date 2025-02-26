# frozen_string_literal: true

module Bridges
  module Chatbot
    def self.shared_secret
      Rails.application.secrets.chatbot_bridge_shared_secret
    end

    class BaseController < Abstract::BridgeAPIController
      before_action :require_authorization_header!

      def require_authorization_header!
        return if request.headers['HTTP_AUTHORIZATION'].present?

        response.headers['WWW-Authenticate'] = 'Bearer realm="chatbot-bridge-api"'

        problem_details(
          'You must provide an Authorization header to access this resource.',
          status: :unauthorized
        )
      end

      def require_valid_token!
        token = TokenSigning.for(:chatbot).decode(request.env.fetch('HTTP_AUTHORIZATION').split('Bearer ')[1])

        if token.valid?
          @user_id = token.to_s
        else
          problem_details(
            'Invalid Signature',
            status: :unauthorized
          )
        end
      end

      def problem_details(title, status:, **)
        render(
          content_type: 'application/problem+json',
          json: {
            title:,
            status: Rack::Utils.status_code(status),
          },
          status:,
          **
        )
      end

      def course_api
        @course_api ||= Xikolo.api(:course).value!
      end

      def quiz_api
        @quiz_api ||= Xikolo.api(:quiz).value!
      end
    end
  end
end
