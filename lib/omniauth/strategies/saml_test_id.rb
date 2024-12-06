# frozen_string_literal: true

require 'omniauth'
require 'ruby-saml'
require 'omniauth/strategies/xikolo_saml'

module OmniAuth
  module Strategies
    class SAMLTestID < XikoloSAML
      # Don't forget to upload the metadata to use this test service:
      # Copy the XML from http://localhost:3000/auth/saml_test_id/metadata
      # to the metadata upload at https://samltest.id/upload.php
      #
      # You may then use the SSO & SLO service for testing purposes
      # If you want to test an IdP-initiated SLO, head over
      # to the advanced options of https://samltest.id/start-idp-test/

      info do
        {
          email: @attributes['urn:oid:0.9.2342.19200300.100.1.3'],
          name: @attributes['urn:oid:2.16.840.1.113730.3.1.241'],
          user_id: @attributes['urn:oid:0.9.2342.19200300.100.1.1'],
        }
      end

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

OmniAuth.config.add_camelization 'saml_test_id', 'SAMLTestID'
