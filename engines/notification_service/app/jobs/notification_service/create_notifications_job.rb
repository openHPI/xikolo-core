# frozen_string_literal: true

module NotificationService
  class CreateNotificationsJob < ApplicationJob
    queue_as :default
    include Notify

    def perform(event_id, subscriber_ids)
      @event = Event.find event_id
      @subscriber_ids = subscriber_ids

      # Create platform notifications for all users
      notify!

      # ...and send out emails to the appropriate recipients
      if @event.send_mail?
        notify_all mail_recipients, @event.mail_template, @event.mail_payload
      end
    end

    private

    def notify!
      @event.notifications = @subscriber_ids.map do |subscriber|
        Notification.new user_id: subscriber
      end
    end

    def mail_recipients
      # Don't send a mail to the user who caused this event
      @subscriber_ids.reject {|user| user == @event.payload['user_id'] }
    end
  end
end
