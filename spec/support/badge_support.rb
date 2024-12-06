# frozen_string_literal: true

require 'jwt'

# Signing algorithm needs to correspond with OpenBadgeBakery service
SIGNING_ALGORITHM = 'RS256'

def verify_assertion(signed_assertion, public_key)
  JWT.decode(
    signed_assertion,
    OpenSSL::PKey::RSA.new(public_key),
    true,
    algorithm: SIGNING_ALGORITHM
  )
  true
rescue OpenSSL::PKey::RSAError, JWT::DecodeError
  false
end
