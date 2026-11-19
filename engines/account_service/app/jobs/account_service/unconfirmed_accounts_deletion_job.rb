# frozen_string_literal: true

module AccountService
class UnconfirmedAccountsDeletionJob < ApplicationJob # rubocop:disable Layout/IndentationWidth
  queue_as :default

  def perform
    User
      .unconfirmed
      .where(archived: false)
      .where(created_at: ...3.days.ago)
      .in_batches(of: 200).destroy_all
  end
end
end
