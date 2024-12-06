# frozen_string_literal: true

module Bridges
  module Chatbot
    class AuthenticationsController < BaseController
      before_action Xi::Controllers::RequireBearerToken.new(
        realm: 'chatbot-bridge-api',
        token: -> { Chatbot.shared_secret }
      )

      before_action :require_authorization_id!

      def create
        user = Account::User.with_authorization(params[:uid]).take!
        token = generate_token(user.id)
        render json: {token:}
      rescue ActiveRecord::RecordNotFound
        problem_details(
          'There is no user for the provided authorization ID.',
          status: :not_found
        )
      end

      private

      def require_authorization_id!
        return if params[:uid].present?

        problem_details(
          'A valid authorization ID must be provided in the request body to generate a token for a user.',
          status: :not_found
        )
      end

      def generate_token(user_id)
        TokenSigning.for(:chatbot).sign(user_id)
      end
    end
  end
end
