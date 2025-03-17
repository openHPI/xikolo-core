# frozen_string_literal: true

class ExternalRegistration
  def initialize(current_user)
    @current_user = current_user
  end

  def enabled?
    @current_user.feature?('integration.external_booking') &&
      JwtTokenGenerator.enabled?
  end

  def token
    return unless enabled?
    return if @current_user.anonymous?

    JwtTokenGenerator.call(user: @current_user)
  end

  class JwtTokenGenerator
    class << self
      def enabled?
        jwt_secret.present?
      end

      def jwt_secret
        Rails.application.secrets.jwt_hmac_secret
      end

      def call(...)
        new(...).generate
      end
    end

    def initialize(user:)
      @user = user
    end

    def generate
      JWT.encode(payload, self.class.jwt_secret, 'HS256')
    end

    private

    def payload
      {
        '_id' => @user.session_id,
        'userID' => @user.id,
        'exp' => 2.days.from_now.to_i, # TODO: Expiration check in booking? Duration to config?
        'iat' => Time.current.to_i,
        'fullname' => @user.full_name,
        'email' => @user.email,
        'organization_name' => @user.affiliation,
      }
    end
  end
end
