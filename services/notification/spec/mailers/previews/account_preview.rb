# frozen_string_literal: true

# Preview all emails at http://localhost:3200/rails/mailers/account
class AccountPreview < ActionMailer::Preview
  def password_reset
    NotificationService::AccountMailer.password_reset(
      {'email' => 'peter@pan.online', 'language' => I18n.locale.to_s},
      Xikolo.base_url.join('reset/my/password')
    )
  end

  def confirm_email
    NotificationService::AccountMailer.confirm_email(
      {'language' => I18n.locale.to_s},
      'peter@pan.online',
      Xikolo.base_url.join('confirm/my/email')
    )
  end

  def welcome_email
    NotificationService::AccountMailer.welcome_email(
      {'email' => 'peter@pan.online', 'language' => I18n.locale.to_s},
      false,
      Xikolo.base_url.join('welcome/to/the/platform')
    )
  end
end
