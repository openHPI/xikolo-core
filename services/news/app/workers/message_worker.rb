# frozen_string_literal: true

class MessageWorker
  include Sidekiq::Job

  def perform(id)
    message = Message.find(id)

    Message::Send.call(message)
  end

  class << self
    def call(message)
      perform_async(message.id)
    end
  end
end
