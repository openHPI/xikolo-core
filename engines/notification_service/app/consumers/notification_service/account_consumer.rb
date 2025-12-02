# frozen_string_literal: true

module NotificationService
class AccountConsumer < Msgr::Consumer # rubocop:disable Layout/IndentationWidth
  def password_reset
    user, _reset = Restify::Promise.new(
      account_api.rel(:user).get({id: payload[:user_id]}),
      account_api.rel(:password_reset).get({id: payload[:token]})
    ).value!

    deliver AccountMailer.password_reset(user, payload[:url])
  rescue Restify::NotFound
    # Triggered when either user does not exist (anymore) or password
    # reset does not exist anymore.
  end

  def confirm_email
    user = account_api.rel(:user).get({id: payload[:user_id]}).value!
    email = user.rel(:email).get({id: payload[:id]}).value!

    deliver AccountMailer.confirm_email(user, email['address'], payload[:url])
  rescue Restify::NotFound
    # Triggered when either user does not exist (anymore) or email
    # address does not exist anymore.
  end

  def welcome_email
    user = account_api.rel(:user).get({id: payload[:user_id]}).value!
    return if user['email'].blank?

    features = user.rel(:features).get.value!

    mandatory_fields = features.key?('account.profile.mandatory_completed')
    url = payload[:confirmation_url]

    deliver AccountMailer.welcome_email(user, mandatory_fields, url)
  rescue Restify::NotFound
    # Triggered when either user does not exist (anymore). Should happen
    # very rarely as this event is triggered after user registration, but
    # it does happen.
  end

  private

  def deliver(mail)
    mail.deliver_now
  rescue Net::SMTPSyntaxError, Net::SMTPFatalError => e
    ::Sentry.capture_exception(e)
    Rails.logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
end
