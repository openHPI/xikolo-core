# frozen_string_literal: true

class Message::Send < ApplicationOperation
  attr_reader :message

  def initialize(message)
    super()

    @message = message
  end

  def call
    message.update!(status: 'sending')

    # Concurrently send message to the specified audience (users or groups)
    message.recipients.each do |recipient|
      RecipientWorker.call(message, recipient)
    end
  end
end
