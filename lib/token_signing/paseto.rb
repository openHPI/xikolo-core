# frozen_string_literal: true

require 'paseto'

module TokenSigning
  ##
  # An adapter for signing / verifying Paseto tokens (see https://paseto.io/)
  # for use as "algorithm" with our +TokenSigning+ facade.
  #
  module Paseto
    class Sign
      def initialize(private_key)
        @private_key = private_key
      end

      def sign(raw_string)
        ::Paseto::V2::Public::SecretKey
          .decode64(@private_key)
          .sign(raw_string)
      end
    end

    class Verify
      def initialize(public_key)
        @public_key = public_key
      end

      def try_verify(signed_token)
        decoded_key = ::Paseto::V2::Public::PublicKey.decode64(@public_key)
        decoded_key.verify(signed_token)
      rescue ::Paseto::Error
        nil
      end
    end

    class << self
      ##
      # A utility method for generating a new keypair, e.g. for use in production config.
      #
      def generate_keys
        key = ::Paseto::V2::Public::SecretKey.generate

        {
          private: key.encode64,
          public: key.public_key.encode64,
        }
      end
    end
  end
end
