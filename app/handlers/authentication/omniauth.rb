# frozen_string_literal: true

module Authentication
  ##
  # Authenticates a user via an OmniAuth payload (SSO).
  #
  class OmniAuth
    def self.call(payload, current_user:)
      authorization = AccountService::Authorization.from_omniauth(payload)

      if authorization.user_id.present?
        return Authentication.start_session_for(authorization.user, authorization:)
      end

      # A logged-in user wants to connect the authorization to their own
      # account, which is decided and handled by the controller.
      if current_user&.logged_in?
        return Result.failure(:user_creation_required, authorization:, new_authorization: true)
      end

      Authentication.link_authorization(
        authorization,
        auto_create: OMNIAUTH_AUTOCREATE.include?(authorization.provider),
        new_authorization: true
      )
    rescue ActiveRecord::RecordInvalid
      # The payload cannot be stored, e.g. because the authorization is
      # already connected to an account the e-mail address now belongs to.
      Result.failure(:invalid_information)
    end
  end
end
