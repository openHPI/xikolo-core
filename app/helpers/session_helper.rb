# frozen_string_literal: true

module SessionHelper
  # NOTE: The following logout handling is copied to `OmniAuth::Strategies::XikoloSAML` for Single-Log-Out.
  def logout
    if current_user.session_id
      begin
        account_api
          .rel(:session)
          .delete({id: current_user.session_id})
          .value!

      # If the session does not exists it has already been deleted by the
      # Account service which is perfectly fine. We do not need to anything
      # then.
      rescue Restify::NotFound
      #
      # On any kind of gateway error or service unavailable we will ignore
      # the error and continue. We invalidate the session on the client anyway.
      # There is no need to show the user an exception is the logout "mostly"
      # worked. Leftover sessions need to be recycled by the Account service.
      #
      # We attach the error to the mnemosyne trace for recording but is likely
      # not an exception relevant for developers.
      rescue Restify::GatewayError => e
        ::Mnemosyne.attach_error(e)

      # On any other failing response we will continue too but report the
      # exception.
      rescue Restify::ResponseError => e
        ::Mnemosyne.attach_error(e)
        ::Sentry.capture_exception(e)
      end
    end

    # If the user signed in through SAML, we want to keep the SAML session to support SLO (Single Log-Out).
    # This allows us to start the SP-initiated SLO workflow, in which we will remove the SAML session completely.
    # Therefore, `preserve_saml_session` is only included here and not mirrored to `OmniAuth::Strategies::XikoloSAML`.
    preserve_saml_session do
      session.clear
    end

    # We must set a session ID here because otherwise
    # `ApplicationController#remember_user`, configured as an after action,
    # will create a new session for `current_user` and store it's ID in the
    # session make logout impossible.
    session[:id] = 'anonymous'
  end

  def preserve_saml_session
    # If available, the SAML response data is restored from the env rack session.
    # For integration testing, the omniauth gem offers to mock `request.env["omniauth.auth"]`, but the SAML response
    # data is saved to the rack session by the omniauth-saml gem, for which no mocking option exists.
    # Thus, the SAML response data can only be retrieved from the omniauth auth_hash during testings.
    saml_uid = session[:saml_uid] || request.env.dig('omniauth.auth', 'uid')
    saml_session_index = session[:saml_session_index] || request.env.dig('omniauth.auth', 'extra', 'session_index')
    saml_provider = session[:saml_provider] || request.env.dig('omniauth.auth', 'provider')

    yield if block_given?

    # If SAML was used for the login, we restore SAML-specific information to the session.
    if saml_uid.present? && saml_session_index.present?
      session[:saml_uid] = saml_uid
      session[:saml_session_index] = saml_session_index
      session[:saml_provider] = saml_provider
    end
  end

  private

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end

  def after_sign_out_path
    # Before continuing, we retrieve and remove the `saml_provider` previously stored in the cookie.
    # Within our application logic, we added it to select the same OmniAuth strategy used for the login.
    # This allows us to support multiple SAML providers simultaneously.
    saml_provider = session.delete(:saml_provider)

    # If a compatible SAML provider was used for login, we initiate the Single-Log-Out.
    if saml_provider.present? && OMNIAUTH_LOGOUT.include?(saml_provider)
      # This path is defined and handled by the `omniauth-saml` gem.
      "#{auth_path(saml_provider)}/spslo"
    else
      # Clearing the session removes all SAML-related data,
      # and also the `id`, which was set to 'anonymous'
      # during logout (see comment above ll.43-47).
      # It needs to be set back to 'anonymous', to
      # avoid being set to a new session ID.
      session.clear
      session[:id] = 'anonymous'
      root_path
    end
  end
end
