# frozen_string_literal: true

module Xi
  module Recaptcha
    ##
    # Handle integration of reCAPTCHA v2 and v3 for verifying user actions.
    class Integration
      include ::Recaptcha::Adapters::ViewMethods
      include ActionView::Helpers::TranslationHelper

      # @return [Boolean] True if reCAPTCHA is enabled, false otherwise.
      def self.enabled?
        Xikolo.config.recaptcha['enabled']
      end

      # @param request [ActionDispatch::Request] The HTTP request object.
      # @param params [Hash] The request parameters.
      # @param action [String] The action to verify.
      def initialize(request:, params:, action:)
        @request = request
        @params = params
        @action = action
        @verification_method = :automatic
      end

      # Verifies the user using either reCAPTCHA v3 or v2.
      # @return [Boolean] True if verification is successful, false otherwise.
      def verified?
        return true unless self.class.enabled?

        [
          V2.new(request: @request, params: @params),
        ].tap do |verifiers|
          unless show_checkbox_recaptcha?
            verifiers.prepend(V3.new(request: @request, params: @params, action: @action))
          end
        end.any?(&:verified?)
      end

      # Switch to manual verification using the checkbox method.
      def require_manual_verification!
        @verification_method = :checkbox
      end

      def show_checkbox_recaptcha?
        @verification_method == :checkbox ||
          @params[:show_checkbox_recaptcha].presence
      end

      # Render the appropriate reCAPTCHA widget based on the used verification method.
      def render
        return unless self.class.enabled?

        if show_checkbox_recaptcha?
          "<p class='recaptcha-hint'>#{I18n.t(:'helpdesk.recaptcha')}</p>".html_safe +
            recaptcha_tags(site_key: V2.site_key, hl: I18n.locale)
        else
          recaptcha_v3(action: @action, site_key: V3.site_key, turbo: true)
        end
      end
    end
  end
end
