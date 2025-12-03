# frozen_string_literal: true

module NewsService
class Message::Deliver < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  attr_reader :message, :recipient

  def initialize(message, recipient)
    super()

    @message = message
    @recipient = recipient
  end

  def call
    recipient.each do |user|
      Delivery::Create.call(message, user)
    end
  end
end
end
