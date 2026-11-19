# frozen_string_literal: true

module NewsService
  class RecipientJob < ApplicationJob
    queue_as :default

    def perform(message_id, recipient)
      message = Message.find(message_id)
      recipient = Recipient.find(recipient, message)

      Message::Deliver.call(message, recipient)
    end
  end
end
