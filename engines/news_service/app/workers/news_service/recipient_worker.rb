# frozen_string_literal: true

module NewsService
class RecipientWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(id, recipient)
    message = Message.find(id)
    recipient = Recipient.find(recipient, message)

    Message::Deliver.call(message, recipient)
  end

  class << self
    def call(message, recipient)
      perform_async(message.id, recipient)
    end
  end
end
end
