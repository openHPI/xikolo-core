# frozen_string_literal: true

# Create a {Message} for an {Announcement} and schedule the message to send
# to all recipients.
#
# Several properties such as the recipients will be copied to the message
# record. A background worker will be scheduled to process the message and send
# an email to each recipient.
#
module NewsService
class Message::Create < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  attr_reader :announcement

  def initialize(announcement, params = {})
    super()

    @announcement = announcement
    @params = params
  end

  def call
    message = Message.create(
      announcement:,
      recipients: @params.fetch(:recipients, announcement.recipients),
      consents: @params.fetch(:consents, []),
      translations: announcement.translations,
      creator_id: @params.fetch(:creator_id, announcement.author_id),
      test: @params.fetch(:is_test, false)
    )

    MessageWorker.call(message)
  end
end
end
