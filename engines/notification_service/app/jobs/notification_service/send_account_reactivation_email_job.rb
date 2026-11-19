# frozen_string_literal: true

module NotificationService
  class SendAccountReactivationEmailJob < ApplicationJob
    def perform(payload)
      user = AccountService::User.find(payload[:user_id])

      AccountMailer.account_reactivation(user, payload[:url]).deliver_now
    rescue ActiveRecord::RecordNotFound
      Sentry.capture_message('User not found for account reactivation email', extra: {user_id: payload[:user_id]})
    end

    private
    def account_api
      @account_api ||= Xikolo.api(:account).value!
    end
  end
end
