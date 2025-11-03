# frozen_string_literal: true

module AccountService
class UnconfirmedAccountsDeletionWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform
    User
      .unconfirmed
      .where(archived: false)
      .where(created_at: ...3.days.ago)
      .in_batches(of: 200).destroy_all
  end
end
end
