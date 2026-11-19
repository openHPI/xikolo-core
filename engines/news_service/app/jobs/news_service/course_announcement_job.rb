# frozen_string_literal: true

module NewsService
class CourseAnnouncementJob < ApplicationJob # rubocop:disable Layout/IndentationWidth
  queue_as :default

  def perform(email_id)
    email = Email.find(email_id)

    NotificationService::AnnouncementJob.perform_later(email.announcement.decorate.as_event.tap do |data|
      if email.test_recipient
        data[:test] = true
        data[:receiver_id] = email.test_recipient
      end
    end)
  end
end
end
