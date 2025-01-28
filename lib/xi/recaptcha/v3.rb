# frozen_string_literal: true

module Xi
  module Recaptcha
    ##
    # V3: "Automatic" invisible reCAPTCHA verification.
    # Used to automatically validate user actions without explicit interaction.
    class V3
      include ::Recaptcha::Adapters::ControllerMethods

      def self.site_key
        Xikolo.config.recaptcha['site_key_v3']
      end

      # @param request [ActionDispatch::Request] The HTTP request object.
      # @param params [Hash] The request parameters.
      # @param action [String] The action to verify.
      def initialize(request:, params:, action:)
        @request = request
        @params = params
        @action = action
      end

      # The method verify_recaptcha from the recaptcha gem needs to access the
      # request object.
      attr_reader :request

      # @return [Boolean] True if verification is successful, false otherwise.
      def verified?
        return false unless recaptcha_token

        options = {
          action: 'helpdesk',
          minimum_score: Xikolo.config.recaptcha['score'],
          secret_key: Rails.application.secrets.recaptcha_v3,
          response: recaptcha_token,
        }

        send(:verify_recaptcha, options)
      end

      private

      # Extracts the Google reCAPTCHA response token from params.
      # For reCAPTCHA v3, the token is stored in params['g-recaptcha-response-data'] under a key specified by @action.
      # If the request is made via JavaScript, include the token manually in the request params as 'recaptcha_token_v3'.
      def recaptcha_token
        @params['recaptcha_token_v3'].presence ||
          @params.dig('g-recaptcha-response-data', @action)
      end
    end
  end
end
