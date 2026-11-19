# frozen_string_literal: true

module Cmi5
  class ApplicationController < ::ApplicationController
    before_action :ensure_cmi5_user

    def self.verifier
      Rails.application.message_verifier('cmi5.tokens')
    end

    private

    def ensure_cmi5_user
      return if current_user.logged_in?

      render json: {error: 'Unauthorized'}, status: :unauthorized
    end

    def authenticate_cmi5_token!
      token = auth_token
      return unauthorized! if token.blank?

      @cmi5_token_payload = self.class.verifier.verify(token, purpose: :cmi5_reporting)
      unauthorized! if @cmi5_token_payload.blank? || @cmi5_token_payload['item_id'].blank?
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
      unauthorized!
    end

    attr_reader :cmi5_token_payload

    def auth_token
      auth_header = request.headers['Authorization'] || request.env['HTTP_AUTHORIZATION']
      return if auth_header.blank? || !auth_header.start_with?('Basic ')

      encoded_credentials = auth_header.sub(/^Basic\s+/, '').strip
      Base64.strict_decode64(encoded_credentials).split(':').first
    rescue ArgumentError
      nil
    end

    def unauthorized!
      render json: {error: 'Unauthorized'}, status: :unauthorized
    end

    def bad_request!
      render json: {error: 'Bad Request'}, status: :bad_request
    end
  end
end
