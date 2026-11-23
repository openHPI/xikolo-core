# frozen_string_literal: true

module Authentication
  ##
  # Authenticates a user by email address and password.
  #
  class Credentials
    def self.call(ident:, password:)
      user = AccountService::User.authenticate(ident, password)
      return Result.failure(:invalid_credentials) unless user

      Authentication.start_session_for(user)
    rescue BCrypt::Errors::InvalidHash
      Result.failure(:invalid_digest)
    end

    ##
    # Checks credentials without starting a session, for cases such as
    # confirming the old password before it is changed.
    #
    def self.verify(ident:, password:)
      user = AccountService::User.authenticate(ident, password)

      user.present? && Authentication.login_blocked?(user).nil?
    rescue BCrypt::Errors::InvalidHash
      false
    end
  end
end
