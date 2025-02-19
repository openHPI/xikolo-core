# frozen_string_literal: true

# NOTE: For security reasons, we should disallow `GET` requests and switch to `POST` requests.
# For now, however, we continue to allow `GET` requests to ease upgrading from OmniAuth 1.x to 2.x.
# In 1.x releases, both `GET` and `POST` requests were allowed, 2.x releases restrict the method to `POST`
# See https://github.com/omniauth/omniauth/releases/tag/v2.0.0
OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true

file = ENV['OMNI_FILE'] || Rails.root.join('config', 'omniauth.yml')

OMNIAUTH_PROVIDERS = [] # rubocop:disable Style/MutableConstant
OMNIAUTH_AUTOCREATE = [] # rubocop:disable Style/MutableConstant
OMNIAUTH_LOGOUT = [] # rubocop:disable Style/MutableConstant

if File.exist?(file)
  # Allow loading symbols. They are needed sometimes as we map the content
  # directly to options. There also is no security issues with that anymore as
  # symbols are garbage collected now. Aliases are fine here too as only the
  # admin can DOS the application.
  omniauth = YAML.safe_load(
    ERB.new(File.read(file)).result,
    permitted_classes: [Symbol],
    aliases: true
  )

  if omniauth.is_a?(Hash) && (config = omniauth[Rails.env])
    config = config.with_indifferent_access

    Rails.application.config.middleware.use OmniAuth::Builder do
      config.each do |name, auth|
        next unless auth

        auth[:provider] ||= name.to_s
        case auth[:provider]
          when 'saml'
            require 'omniauth/strategies/xikolo_saml'
            provider OmniAuth::Strategies::XikoloSAML, auth.merge(name:)
          when 'hpi', 'openid_connect'
            provider :openid_connect, auth
          when 'hpi_saml'
            require 'omniauth/strategies/hpi'
            provider :hpi, auth.merge(name:)
          when 'egovcampus'
            require 'omniauth/strategies/egovcampus'
            provider :egovcampus, auth.merge(name:)
          when 'mein_bildungsraum'
            require 'omniauth/strategies/mein_bildungsraum'
            provider :mein_bildungsraum, auth.merge(name:)
          when 'saml_test_id'
            require 'omniauth/strategies/saml_test_id'
            provider :saml_test_id, auth.merge(name:)
          else
            Rails.logger.warn { "Unknown OmniAuth provider in #{name}: #{auth[:provider]}" }
            next
        end

        OMNIAUTH_PROVIDERS << name.to_sym if auth.fetch(:visible, false)
        OMNIAUTH_AUTOCREATE << name if auth.fetch(:autocreate, false)
        OMNIAUTH_LOGOUT << name if auth.fetch(:idp_slo_service_url, false)
      end
    end
  end
end
