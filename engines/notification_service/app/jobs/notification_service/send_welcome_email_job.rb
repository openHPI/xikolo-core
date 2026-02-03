# frozen_string_literal: true

module NotificationService
  class SendWelcomeEmailJob < ApplicationJob
    def perform(user_id, confirmation_url)
      user = account_api.rel(:user).get({id: user_id}).value!
      return if user['email'].blank?

      features = user.rel(:features).get.value!

      mandatory_fields = features.key?('account.profile.mandatory_completed')

      AccountMailer.welcome_email(user, mandatory_fields, confirmation_url).deliver_now
    rescue Restify::NotFound
      Sentry.capture_message("User with ID #{user_id} not found when sending welcome email")
    end

    private
    def account_api
      @account_api ||= Xikolo.api(:account).value!
    end
  end
end
