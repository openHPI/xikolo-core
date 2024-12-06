# frozen_string_literal: true

class Message::Deliver < ApplicationOperation
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
