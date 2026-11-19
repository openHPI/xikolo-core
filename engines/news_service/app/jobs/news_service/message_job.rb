# frozen_string_literal: true

module NewsService
  class MessageJob < ApplicationJob
    queue_as :default

    def perform(message_id)
      message = Message.find(message_id)
      Message::Send.call(message)
    end
  end
end
