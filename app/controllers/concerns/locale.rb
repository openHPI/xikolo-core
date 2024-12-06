# frozen_string_literal: true

module Locale
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  # This will check and prefer locales from different sources
  # in this order:
  #
  #   1. Explicit set locale from query parameter
  #   2. Locale from current session cookie
  #   3. Preferred language from signed in user
  #   4. Language from HTTP content negotiation
  #   5. Application configured default locale
  #
  def set_locale
    I18n.locale = begin
      load_query_locale ||
        load_session_locale ||
        load_user_locale ||
        load_browser_locale ||
        Xikolo.config.locales['default']
    end
  end

  # Return value of the query parameter that contains a locale
  # value top change to.
  #
  # This currently must be public API as it is overriden in some
  # controllers to disable query parameter based locale switching.
  def locale_param
    params[:locale]
  end

  private

  # Check if a query parameter `locale` is set.
  #
  # This happends primarly when a user clicks on a language link in
  # the language menu. If the locale is available it will be saved
  # to the session (important for anonymous users). If the current user
  # is logged in their preferred language will be changed too.
  #
  def load_query_locale
    return unless (locale = sanitize_locale(locale_param))

    # Store explicit set locale to session
    session[:locale] = locale

    # Update logged in users language preference
    if current_user.logged_in?
      Xikolo.api(:account).value!.rel(:user).patch({
        language: locale,
      }, {id: current_user.id}).value!
    end

    locale
  end

  # Detect a session language e.g. set by the query parameter.
  def load_session_locale
    sanitize_locale session[:locale].presence || session[:language]
  end

  # Check if current user has a preferred language.
  #
  # Make sure to use `User#preferred_language` and not `User#language`.
  # The latter is always filled in by the account service and used
  # by service backends.
  #
  def load_user_locale
    sanitize_locale current_user.preferred_language
  end

  # Detect locale from HTTP content negotiation.
  #
  # This must only use enabled, e.g. available and non-hidden locales.
  #
  def load_browser_locale
    http_accept_language.compatible_language_from Xikolo.config.locales['available']
  end

  # Sanitize given locale.
  #
  # Return `nil` if the locale is blank or not available.
  #
  def sanitize_locale(locale)
    return if locale.blank?
    return unless Xikolo.config.locales['available'].include?(locale)

    locale
  end
end
