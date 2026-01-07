# frozen_string_literal: true

require 'hashie/mash'

module NotificationService
class CourseWelcomeMailer < ApplicationMailer # rubocop:disable Layout/IndentationWidth
  include NotificationService::MailerHelper

  layout 'notification_service/foundation'

  def welcome_mail(receiver, payload)
    @receiver = receiver
    I18n.with_locale get_language(@receiver.language) do
      @payload = Hashie::Mash.new payload
      @subject = t('notification_service.course_welcome_mailer.welcome_mail.subject', course_title: @payload.title)

      @payload.mailheader_type = t('notification_service.course_welcome_mailer.welcome_mail.mailheader_type')
      @payload.mailheader_info = @payload.title

      mail(
        to: @receiver.email,
        subject: @subject,
        template_path: 'notification_service/course_welcome_mailer',
        template_name: 'welcome'
      )
    end
  end
end
end
