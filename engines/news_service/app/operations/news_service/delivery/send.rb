# frozen_string_literal: true

# Create a {Delivery} record for a specific message and user.
#
# After creating the database delivery record in a queued state a background
# worker will be scheduled to actually send the message. This order allows the
# background worker to issue an ON UPDATE lock the database record when sending
# the email and changing the state. This should avoid sending message to a user
# multiple times.
#
module NewsService
class Delivery::Send < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  attr_reader :delivery, :user

  def initialize(delivery, user)
    super()

    @delivery = delivery
    @user = user
  end

  def call
    delivery.with_lock do
      next if delivery.sent?

      AnnouncementMailer.call(delivery.message, user)

      delivery.update!(sent_at: Time.now.utc)
    end
  end
end
end
