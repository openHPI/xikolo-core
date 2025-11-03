# frozen_string_literal: true

# The NotifyOutbox module adds an in-memory outbox for notification
# events to a model.
#
# An outbox collects notify events emitted while processing, for
# example, when creating or updating records, and only emits them after
# the transaction has been committed. This is similar to the
# transactional outbox pattern, but without persistence to the database.
#
# Events can be skipped depending on other events already being present,
# such as skipping adding :update notifications when the records was
# created within the transaction and the :create event is already
# present.
#
# Events are deduplicated, meaning that only one event with the same
# name will be emitted, even when multiple are added.
#
module AccountService
module NotifyOutbox # rubocop:disable Layout/IndentationWidth
  extend ActiveSupport::Concern

  included do
    after_commit(:process_outbox)
  end

  # Add a new event to the outbox, unless any of the events specified in
  # `skip:` already exist in the outbox.
  #
  # Example:
  #
  #     model.notify(:create)
  #     model.notify(:update, skip: [:create])
  #
  def notify(event, skip: [])
    return false if outbox.intersect?(skip)

    outbox << event

    true
  end

  private

  def outbox
    @outbox ||= Set.new
  end

  def process_outbox
    reload unless destroyed? # refresh model data

    # If the record is updated in the same transaction as it was
    # created, we only emit the :create event. This mimics the
    # `#after_commit(on:)` behavior.
    outbox.delete(:update) if outbox.include?(:create)

    outbox.each do |event|
      publish_notify(event)
    end
  ensure
    outbox.clear
  end
end
end
