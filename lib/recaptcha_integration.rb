# frozen_string_literal: true

class RecaptchaIntegration
  include Recaptcha::Adapters::ControllerMethods
  include Recaptcha::Adapters::ViewMethods
  include ActionView::Helpers::TranslationHelper

  # The method verify_recaptcha from the recaptcha gem needs to access the request object
  attr_reader :request

  def initialize(request:, params:, action:)
    @request = request
    @params = params
    @action = action
    @verification_method = :automatic
  end

  def self.enabled?
    Xikolo.config.recaptcha['enabled']
  end

  def verified?
    return true unless self.class.enabled?

    # Return true if either verification succeeded
    verified_automatically? || verified_via_checkbox?
  end

  def require_manual_verification!
    @verification_method = :checkbox
  end

  def show_checkbox_recaptcha?
    @verification_method == :checkbox || @params[:show_checkbox_recaptcha].present?
  end

  def render
    return unless self.class.enabled?

    if show_checkbox_recaptcha?
      "<p class='recaptcha-hint'>#{I18n.t(:'helpdesk.recaptcha')}</p>".html_safe +
        recaptcha_tags(site_key: Xikolo.config.recaptcha['site_key_v2'], hl: I18n.locale)
    else
      recaptcha_v3(action: @action, site_key: Xikolo.config.recaptcha['site_key_v3'], turbo: true)
    end
  end

  private

  # reCAPTCHA v3 - Automatic verification
  def verified_automatically?
    return false unless recaptcha_token_v3

    v3_options = {
      action: 'helpdesk',
      minimum_score: Xikolo.config.recaptcha['score'],
      secret_key: Rails.application.secrets.recaptcha_v3,
      response: recaptcha_token_v3,
    }

    send(:verify_recaptcha, v3_options)
  end

  # reCAPTCHA v2 - Checkbox verification
  def verified_via_checkbox?
    return false unless recaptcha_token_v2

    v2_options = {
      secret_key: Rails.application.secrets.recaptcha_v2,
      response: recaptcha_token_v2,
    }
    send(:verify_recaptcha, v2_options)
  end

  # Extracts the Google reCAPTCHA response token from params.
  # For reCAPTCHA v3, the token is stored in params['g-recaptcha-response-data'] under a key specified by @action.
  # If the request is made via JavaScript, include the token manually in the request params as 'recaptcha_token_v3'.
  def recaptcha_token_v3
    @params['recaptcha_token_v3'].presence ||
      @params.dig('g-recaptcha-response-data', @action)
  end

  # For reCAPTCHA v2, the token is stored in params['g-recaptcha-response'].
  # If the request is made via JavaScript, include the token manually in the request params as 'recaptcha_token_v2'.
  def recaptcha_token_v2
    @params['recaptcha_token_v2'].presence ||
      @params['g-recaptcha-response']
  end
end
