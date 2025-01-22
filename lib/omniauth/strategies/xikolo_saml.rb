# frozen_string_literal: true

require 'omniauth'
require 'omniauth-saml'

module OmniAuth
  module Strategies
    class XikoloSAML < OmniAuth::Strategies::SAML
      # During the request phase, we store the session ID in the `request.params`.
      # It is passed through via SAML's standard `RelayState` parameter, so it will be preserved and can be used in the
      # callback phase.
      option :idp_sso_service_url_runtime_params, {
        session_id: 'RelayState',
      }

      # The `RelayState` is used by the `omniauth-saml` gem to specify a redirection target after a successful logout.
      # As a default redirection target, we use the application homepage, just like with regular logouts.
      option :slo_default_relay_state, Xikolo.base_url.to_s

      option :idp_slo_session_destroy, proc {|env, session|
        ### PART I: Set cookie-specific options
        if Rails.env.development?
          # For development purposes, we want to assume a secure connection behind a TLS-terminating proxy.
          # If this option is not set, our session cookie is not sent by Rack (due to the `secure` flag).
          env['HTTP_X_FORWARDED_PROTO'] = 'https'
        end

        # We want to ensure that the new cookie (with an empty session) is set by the client.
        # Doing so will definitely overwrite an existing session in the browser.
        # Our mechanism will only work through HTTPS and with the following two options.
        env['rack.session'].options[:secure] = true
        env['rack.session'].options[:same_site] = :none

        ### PART II: Delete all information from the current session
        # If the cookie is not included with the SLO request, we cannot invalidate the existing session in
        # the account service. Thus, any user previously obtaining a copy of the cookie would still be able to use it.
        # The following mechanism is taken from `SessionHelper#logout`.
        begin
          Xikolo.api(:account).value!
            .rel(:session)
            .delete(id: session['id'])
            .value!

          # If the session does not exists it has already been deleted by the
          # Account service which is perfectly fine. We do not need to anything
          # then.
        rescue Restify::NotFound
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

        session.clear

        # We must set a session ID here because otherwise
        # `ApplicationController#remember_user`, configured as an after action,
        # will create a new session for `current_user` and store it's ID in the
        # session make logout impossible.
        session[:id] = 'anonymous'
      }

      def request_phase
        ::Mnemosyne.trace('XikoloSAML.request_phase',
          meta: {session: session.instance_variable_get(:@delegate)}) { super }
      end

      def callback_phase
        ::Mnemosyne.trace('XikoloSAML.callback_phase',
          meta: {session: session.instance_variable_get(:@delegate)}) { super }
      end

      def with_settings
        # Advertise the SLO (Single Log-Out) URL in the SAML metadata.
        # This allows identity providers to discover SLO support and configure it automatically.
        options[:single_logout_service_url] ||= slo_path

        # When this is not an authorization request for SSO login (the `id` in the session
        # is present), force a new authorization for the IdP, e.g. to be able to connect
        # additional SSO accounts for the very same IdP.
        # The check for the request path ensures this is considered for the initiation phase
        # only (and not for the callback phases nor the SLO request, even though the passed-in
        # options are also validated and thus ignored if they do not apply).
        if session['id'].present? && session['id'] != 'anonymous' && on_path?(request_path)
          options[:force_authn] = true

          # Store the session ID in the SAML RelayState if a user is logged in, so that it can be accessed for
          # requesting the current user in the callback phase and to add the new identity to the existing account.
          request.params['session_id'] = OmniAuth::NonceStore.add session['id']
        end

        # NOTE: During the activation phase of SLO support, we temporarily need to patch the `omniauth-saml` gem.
        # Within the gem, the `saml_uid` from the session is compared to the `name_id` of the logout request.
        # If those don't match, the logout request will fail with an (unhandled) exception.
        #
        # In previous Xikolo releases, we (unintentionally) removed the `saml_uid` and `saml_session_index`
        # yielding to the error mentioned above, which has been fixed in March 2022.
        # Hence, the changes below should be removed after a migration window of SLO has passed.
        if on_subpath?(:slo) && request.params['SAMLRequest'] && session['saml_uid'].blank?
          logout_request = OneLogin::RubySaml::SloLogoutrequest.new(
            request.params['SAMLRequest'],
            {settings: OneLogin::RubySaml::Settings.new(options), get_params: request.params}
          )
          session['saml_uid'] = logout_request.name_id
        end

        super
      end

      def slo_path
        # This path is defined and handled by the `omniauth-saml` gem.
        "#{full_host}#{script_name}#{request_path}/slo"
      end
    end
  end
end
