# frozen_string_literal: true

module OmniAuth
  class NonceStore
    MAXIMUM_AGE = 30.minutes

    def self.build_cache_key(nonce)
      "omniauth_nonce_#{nonce}"
    end

    def self.add(value)
      nonce = SecureRandom.urlsafe_base64
      Rails.cache.write(build_cache_key(nonce), value, expires_in: MAXIMUM_AGE)
      nonce
    end

    def self.read(nonce)
      Rails.cache.read(build_cache_key(nonce))
    end

    def self.delete(nonce)
      Rails.cache.delete(build_cache_key(nonce))
    end

    def self.pop(nonce)
      value = read(nonce)
      delete(nonce) if value
      value
    end
  end
end
