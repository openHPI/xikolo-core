# frozen_string_literal: true

module Xi
  module Recaptcha
    ##
    # V2: "Manual" checkbox reCAPTCHA verification.
    # Used when user interaction is required for verification.
    class V2
      include ::Recaptcha::Adapters::ControllerMethods

      def self.site_key
        Xikolo.config.recaptcha['site_key_v2']
      end

      # @param request [ActionDispatch::Request] The HTTP request object.
      # @param params [Hash] The request parameters.
      def initialize(request:, params:)
        @request = request
        @params = params
      end

      # The method verify_recaptcha from the recaptcha gem needs to access the
      # request object.
      attr_reader :request

      # @return [Boolean] True if verification is successful, false otherwise.
      def verified?
        return false unless recaptcha_token

        options = {
          secret_key: Rails.application.secrets.recaptcha_v2,
          response: recaptcha_token,
        }

        send(:verify_recaptcha, options)
      end

      private

      # Extracts the Google reCAPTCHA response token from params.
      # For reCAPTCHA v2, the token is stored in params['g-recaptcha-response'].
      # If the request is made via JavaScript, include the token manually in the request params as 'recaptcha_token_v2'.
      def recaptcha_token
        @params['recaptcha_token_v2'].presence ||
          @params['g-recaptcha-response']
      end
    end
  end
end
