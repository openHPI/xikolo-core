# frozen_string_literal: true

module Bridges
  module Chatbot
    class UsersController < BaseController
      before_action :require_valid_token!

      # We are inheriting @user_id from the `BaseController`,
      # which is the decoded token.
      def show
        render json: {id: @user_id}
      end
    end
  end
end
