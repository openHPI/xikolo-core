# frozen_string_literal: true

module NotificationService
  class SendPasswordResetEmailJob < ApplicationJob
    def perform(payload)
      user, _reset = Restify::Promise.new(
        account_api.rel(:user).get({id: payload[:user_id]}),
        account_api.rel(:password_reset).get({id: payload[:token]})
      ).value!

      AccountMailer.password_reset(user, payload[:url]).deliver_now
    rescue Restify::NotFound
      # Triggered when either user does not exist (anymore) or password
      # reset does not exist anymore.
    end

    private
    def account_api
      @account_api ||= Xikolo.api(:account).value!
    end
  end
end
