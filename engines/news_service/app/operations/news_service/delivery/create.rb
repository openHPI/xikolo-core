# frozen_string_literal: true

# Create a {Delivery} record for a specific message and user.
#
# After creating the database delivery record in a queued state a background
# job will be scheduled to actually send the message. This order allows the
# background job to issue an ON UPDATE lock the database record when sending
# the email and changing the state. This should avoid sending message to a user
# multiple times.
#
module NewsService
class Delivery::Create < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  attr_reader :message, :user

  def initialize(message, user)
    super()

    @message = message
    @user = user
  end

  def call
    delivery = Delivery.create!(
      message:,
      user_id: user.fetch('id')
    )

    DeliveryJob.perform_later(delivery.id, user.as_json.slice('id', 'email', 'language'))
  rescue ActiveRecord::RecordNotUnique
    # Message has been sent/will be sent to the user,
    # so we're total fine; do nothing here
  end
end
end
