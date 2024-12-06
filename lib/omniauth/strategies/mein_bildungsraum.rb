# frozen_string_literal: true

require 'omniauth'
require 'ruby-saml'
require 'omniauth/strategies/xikolo_saml'

module OmniAuth
  module Strategies
    class MeinBildungsraum < XikoloSAML
      option :attribute_service_name, 'openHPI'

      # We don't request any specific attributes (statements) to get all automatically.
      option :request_attributes, {}
      option :attribute_statements, {}

      # We want to specify some security options ourselves
      option :security, {
        digest_method: XMLSecurity::Document::SHA512,
        signature_method: XMLSecurity::Document::RSA_SHA512,
        metadata_signed: true, # Enable signature on Metadata
        authn_requests_signed: true, # Enable signature on AuthNRequest
        logout_requests_signed: true, # Enable signature on Logout Request
        logout_responses_signed: true, # Enable signature on Logout Response
        want_assertions_signed: true, # Require the IdP to sign its SAML Assertions
        want_assertions_encrypted: true, # Invalidate SAML messages without an EncryptedAssertion
      }

      uid { @name_id || @attributes['urn:oid:0.9.2342.19200300.100.1.1'] }
    end
  end
end

OmniAuth.config.add_camelization 'mein_bildungsraum', 'MeinBildungsraum'
