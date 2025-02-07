# frozen_string_literal: true

class Account::SessionsController < Abstract::FrontendController
  include Xikolo::Account
  include SessionHelper

  skip_before_action :verify_authenticity_token, only: [:authorization_callback]
  skip_after_action :remember_user

  RACK_ATTACK_MAXRETRY = 15
  RACK_ATTACK_FINDTIME = 1.minute
  RACK_ATTACK_BANTIME  = 1.hour

  before_action :check_logged, only: [:new]
  before_action :restrict_native_login, only: [:create]

  def new
    if session[:login_failed]
      session.delete(:login_failed)
      return
    end

    @redirect_param = target_url

    if params[:connect_auth_id] && request.post?
      add_flash_message :notice, t(
        :'flash.notice.login_connect_auth',
        brand: Xikolo.config.site_name,
        provider: t(:"account.sessions.auth_connect.provider_label.#{params[:provider]}")
      )
      @connect_auth_id = params[:connect_auth_id]
    end

    if params[:authorization]
      @authorization = Authorization.find params[:authorization]
      Acfs.run

      render 'auth_connect' if @authorization
    end
  end

  def create
    @handler = AuthenticationHandler.new(login:)

    handle!
  rescue AuthenticationHandler::UnsupportedAuthMethod => e
    # The error can be thrown from AuthenticationHandler when incomplete
    # parameters are passed (for example, only "password" but no
    # "login"). This should never happen in normal requests and might
    # indicate broken or invalid forms.
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)

    add_flash_message :error, t(:'flash.error.generic')
    redirect_to new_session_path
  end

  def destroy
    logout
    add_flash_message :notice, t(:'flash.success.logged_out')
    redirect_to after_sign_out_path
  end

  def authorization_callback
    @handler = AuthenticationHandler.new(omniauth: request.env['omniauth.auth'])

    handle!
  end

  private

  def restrict_native_login
    # Native login is enabled
    return if current_user.feature?('account.login')

    # Return if this is an SSO login attempt.
    # This also covers the scenario with external platform login (no flipper
    # and portal issues an SSO login attempt).
    return if login[:authorization].present?

    # Return if this is an attempt to connect an SSO account with a
    # native account. In this case, the user needs to provide native account
    # credentials and regularly log in to the account.
    return if login[:connect_auth_id].present?

    raise AbstractController::ActionNotFound
  end

  # This overwrites a method from
  # `ActionController::RequestForgeryProtection`. We don't need to
  # redirect via `#login_url`, since this can only happen with a native
  # login form, not with the SSO-based authentication.
  def handle_unverified_request
    case params[:action]
      when 'create'
        add_flash_message :error, t(:'flash.error.session_expired')
        redirect_to new_session_url
      else
        super
    end
  end

  def check_logged
    redirect_to target_url if current_user.authenticated?
  end

  def login
    params[:login]&.permit(
      :authorization,
      :autocreate,
      :connect_auth_id,
      :email,
      :password,
      :redirect_url
    ) || {}
  end

  def target_url(fallback: dashboard_url)
    redirect_url || cookie_url || fallback
  end

  def cookie_url
    return if cookies.signed[:stored_location].blank?

    URI.join(request.base_url, cookies.signed[:stored_location]).to_s
  end

  def redirect_url
    return if redirect_param.blank?

    uri  = URI.parse(URI.decode_www_form_component(redirect_param))
    base = URI.parse(request.base_url)

    return if uri.host.present? && uri.host != base.host

    base.path  = uri.path
    base.query = uri.query

    base.to_s
  rescue URI::InvalidURIError
    nil
  end

  def redirect_param
    if login[:redirect_url].present?
      login[:redirect_url]
    elsif params[:redirect_url].present?
      params[:redirect_url]
    elsif params[:to].present?
      params[:to]
    end
  end

  def handle!
    if @handler.authenticated?
      handle_authenticated!
    elsif @handler.new_authorization? && current_user.logged_in?
      handle_new_authorization!
    else
      handle_failure!
    end
  end

  def handle_authenticated!
    assign_session!

    if login[:connect_auth_id].present?
      authorization =
        Xikolo::Account::Authorization.find login[:connect_auth_id]
      Acfs.run
      begin
        authorization.update_attributes!({user_id: @handler.session.user_id})
      rescue Acfs::InvalidResource => e
        # If there is already an account with the authorization's email address,
        # don't add the authorization to the current user
        if e.errors['provider'].include? 'email_already_used_for_another_account'
          add_flash_message :error, helpers.t(:'flash.error.enterprise_login_already_assigned')
          redirect_to dashboard_url and return
        end

        raise
      end
    end

    if @handler.new_authorization? || authorization
      authorization ||= @handler.authorization
      add_flash_message :success, t(:'flash.success.auth_added',
        brand: Xikolo.config.site_name,
        provider: t(:"account.sessions.auth_connect.provider_label.#{authorization.provider}"))
    end

    if @in_app
      handle_mobile_application!
    else
      target = if current_user.logged_in? && session[:saml_provider] != 'egovcampus'
                 target_url(fallback: dashboard_profile_url)
               else
                 target_url
               end
      cookies.delete :stored_location if cookies.signed[:stored_location]
      redirect_to target
    end
  end
  # rubocop:enable all

  def handle_mobile_application!
    token = Xikolo.api(:account).value!.rel(:tokens).post(user_id: @handler.session.user_id).value!.token
    redirect_to auth_path(provider: 'app', token:)
  end

  def handle_failure!
    if @handler.user_creation_required?
      # For SLO support, the name of the authorization provider is copied to the user's cookie.
      preserve_saml_session
      # This is the case where users connect a new authorization to an existing account.
      # The controller will render the 'auth_connect' template.
      redirect_to new_session_url(authorization: @handler.authorization)
    else
      count_failed_login_attempt!
      session[:login_failed] = true
      store_location(redirect_param)
      # This can also happen for SSO authentication, i.e., when native
      # login is disabled.
      redirect_external(
        login_url,
        error: format_error_message(@handler.error_code)
      )
    end
  end

  def handle_new_authorization!
    @handler.authorization.update_attributes!({user_id: current_user.id})

    add_flash_message :success, t(:'flash.success.auth_added',
      brand: Xikolo.config.site_name,
      provider: t(:"account.sessions.auth_connect.provider_label.#{@handler.authorization.provider}"))

    if @in_app
      handle_mobile_application!
    else
      target = target_url(fallback: dashboard_profile_url)
      cookies.delete :stored_location if cookies.signed[:stored_location]
      redirect_to target
    end
  rescue Acfs::InvalidResource => e
    # If there is already an account with the authorization's email address,
    # don't add the authorization to the current user
    raise unless e.errors['provider'].include? 'email_already_used_for_another_account'

    add_flash_message :error, helpers.t(:'flash.error.enterprise_login_already_assigned')
    redirect_to dashboard_url
  end

  def count_failed_login_attempt!
    discriminator = request.remote_ip
    key_prefix    = 'allow2ban'

    # see https://github.com/kickstarter/rack-attack/blob/037e52ba5d760584e5b43b8be59c8ba4f19c62dc/lib/rack/attack/fail2ban.rb#L34
    count = Rack::Attack.cache.count("#{key_prefix}:count:#{discriminator}", RACK_ATTACK_FINDTIME)
    if count >= RACK_ATTACK_MAXRETRY
      Rack::Attack.cache.write("#{key_prefix}:ban:#{discriminator}", 1, RACK_ATTACK_BANTIME)
    end
  end

  def assign_session!
    session = @handler.session

    if session&.valid? && session.user_id.present?
      # Clear all information within the user's cookie except for the SAML session
      preserve_saml_session do
        reset_session
        self.session[:id] = session.id
      end
    else
      raise ArgumentError.new "INVALID SESSION: #{session.errors}"
    end
  end

  def format_error_message(ident)
    case ident
      when 'invalid_credentials'
        t :'flash.error.invalid_credentials'

      when 'unconfirmed_user'
        verifier = ::Account::ConfirmationsController.verifier
        payload = verifier.generate(@handler.ident.to_s, expires_in: 1.hour)

        t :'flash.error.unconfirmed_user',
          url: new_account_confirmation_path(request: payload)

      when 'invalid_digest'
        t :'flash.error.invalid_digest', url: new_account_reset_path

      else
        t :'flash.error.generic'
    end
  end
end
