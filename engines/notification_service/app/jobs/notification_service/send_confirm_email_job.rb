# frozen_string_literal: true

module NotificationService
  class SendConfirmEmailJob < ApplicationJob
    def perform(payload)
      user = account_api.rel(:user).get({id: payload[:user_id]}).value!
      email = user.rel(:email).get({id: payload[:id]}).value!

      AccountMailer.confirm_email(user, email['address'], payload[:url]).deliver_now
    rescue Restify::NotFound
      # Triggered when either user does not exist (anymore) or email
      # address does not exist anymore.
    end

    private
    def account_api
      @account_api ||= Xikolo.api(:account).value!
    end
  end
end
