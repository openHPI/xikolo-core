# frozen_string_literal: true

# Provides method to detect TLS certificate authentication and
# automatically log in users.
module AutoLogin
  extend ActiveSupport::Concern

  included do
    before_action :auto_login, if: lambda {
      AutoLogin.enabled? && current_user.anonymous?
    }

    before_action :confirm_auto_login, if: lambda {
      AutoLogin.enabled? && current_user.authenticated?
    }
  end

  class_methods do
    # Disables auto login for a controller
    #
    # Passes kwargs to `#skip_before_action` to support e.g. `if`, `only`,
    # `except` as usual for Rails callbacks.
    def skip_auto_login!(**)
      skip_before_action(:auto_login, :confirm_auto_login, **)
    end
  end

  # Check if the request comes with an SSL client certificate that was issued
  # for a configured domain. If matching the user is automatically redirected
  # to their enterprise login.
  def auto_login
    return if logout_cooldown?
    return unless auto_login_possible?

    # Remember we are doing auto login to show flash message when returning.
    cookies.signed[:confirm_auto_login] = true

    if params[:controller] != 'home'
      redirect_path = OmniAuth::Strategies::XikoloSAML.sign request.fullpath
      return redirect_to auth_path(AutoLogin.auth_provider, redirect_path:)
    end

    redirect_to auth_path(AutoLogin.auth_provider)
  end

  def confirm_auto_login
    return unless cookies.signed[:confirm_auto_login]

    add_flash_message :success, t(:'flash.success.auto_login')
    cookies.delete :confirm_auto_login
  end

  private

  def logout_cooldown?
    if cookies.signed[:logout_cooldown]&.positive?
      cookies.signed[:logout_cooldown] -= 1
      return true
    end

    cookies.delete :logout_cooldown
    false
  end

  def auto_login_possible?
    return false if request.env['HTTP_X_SSL_ISSUER'].blank?

    AutoLogin.issuer_domain.any? do |domain|
      request.env['HTTP_X_SSL_ISSUER'].end_with? domain
    end
  end

  class << self
    def enabled?
      Xikolo.config.auto_login['enabled']
    end

    def issuer_domain
      Array.wrap Xikolo.config.auto_login['issuer_domain']
    end

    def auth_provider
      Xikolo.config.auto_login['auth_provider']
    end
  end
end
