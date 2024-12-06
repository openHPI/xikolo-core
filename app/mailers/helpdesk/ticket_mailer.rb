# frozen_string_literal: true

module Helpdesk
  class TicketMailer < ::ApplicationMailer
    default from: 'helpdesk-mailer@openhpi.de'

    def new_ticket_email(ticket)
      @ticket = ticket

      mail(
        to: Xikolo.config.helpdesk_email,
        subject: "#{get_prefix(ticket)}#{ticket.title || 'No Title'}",
        reply_to: ticket.mail
      )
    end

    private

    def get_prefix(ticket)
      return '' unless ticket.course

      course = ticket.course

      if course.channel.present?
        "#{course.channel.code} - #{course.course_code}: "
      else
        "#{course.course_code}: "
      end
    end
  end
end
