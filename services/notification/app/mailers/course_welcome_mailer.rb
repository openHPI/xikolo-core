# frozen_string_literal: true

require 'hashie/mash'
class CourseWelcomeMailer < ApplicationMailer
  include MailerHelper

  layout 'foundation'

  def welcome_mail(receiver, payload)
    @receiver = receiver
    I18n.with_locale get_language(@receiver.language) do
      @payload = Hashie::Mash.new payload
      @subject = t('.subject', course_title: @payload.title)

      @payload.mailheader_type = t('.mailheader_type')
      @payload.mailheader_info = @payload.title

      mail(
        to: @receiver.email,
        subject: @subject,
        template_path: 'course_welcome_mailer',
        template_name: 'welcome'
      )
    end
  end
end
