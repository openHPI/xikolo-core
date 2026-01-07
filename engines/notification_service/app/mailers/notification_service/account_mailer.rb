# frozen_string_literal: true

module NotificationService
class AccountMailer < ApplicationMailer # rubocop:disable Layout/IndentationWidth
  include NotificationService::MailerHelper

  layout 'notification_service/foundation'

  def password_reset(user, url)
    @url = url

    return unless user['email'] # deleted user

    I18n.with_locale(get_language(user['language'])) do
      subject = I18n.t 'notification_service.notifications.account_mailer.password_reset.subject',
        site_name: Xikolo.config.site_name
      mail to: user['email'], subject:
    end
  end

  def confirm_email(user, address, url)
    @url = url

    send_email(:confirm_email, user, address)
  end

  def welcome_email(user, mandatory_fields, url)
    @mandatory_fields = mandatory_fields
    @url = url

    send_email(:welcome_email, user)
  end

  private

  def send_email(mailer, user, email = user['email'])
    I18n.with_locale(get_language(user['language'])) do
      @payload = email_payload(mailer)

      mail to: email,
        subject: I18n.t("notification_service.notifications.account_mailer.#{mailer}.subject",
          site_name: Xikolo.config.site_name)
    end
  end

  def email_payload(mailer)
    Hashie::Mash.new(
      mailheader_type: I18n.t("notification_service.notifications.account_mailer.#{mailer}.mailheader_type",
        site_name: Xikolo.config.site_name)
    )
  end
end
end
