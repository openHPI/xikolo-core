# frozen_string_literal: true

##
# A registry for algorithms used for signing / verifying cryptographic tokens
#
module TokenSigning
  class << self
    def register(name, sign: nil, verify: nil)
      registry[name] = {sign:, verify:}.compact
    end

    ##
    # Use the registered algorithm for signing or verifying tokens.
    #
    def for(name)
      Proxy.new registry.fetch(name)
    end

    private

    def registry
      @registry ||= {}
    end
  end

  ##
  # Try to verify a signed token with multiple verifiers.
  #
  # Only when none of them can decode and validate the token, verification will
  # not be successful.
  #
  # This decorator can be used when tokens could have been signed in different
  # ways (e.g. because of key rotation).
  #
  class VerifyMultiple
    def initialize(*verifiers)
      @verifiers = verifiers
    end

    def try_verify(signed_token)
      @verifiers.each do |v|
        decoded = v.try_verify(signed_token)
        return decoded if decoded
      end

      nil
    end
  end

  class Proxy
    def initialize(options)
      @options = options
    end

    def sign(raw_string)
      @options.fetch(:sign).sign(raw_string)
    end

    def decode(signed_token)
      DecryptedToken.new(@options.fetch(:verify).try_verify(signed_token))
    end
  end

  class DecryptedToken
    def initialize(decrypted)
      @decrypted = decrypted
    end

    def valid?
      !@decrypted.nil?
    end

    def to_s
      raise InvalidSignature unless valid?

      @decrypted
    end
  end

  class InvalidSignature < ::ArgumentError
  end
end
