# frozen_string_literal: true

module AccountService
class ApplicationJob < ActiveJob::Base # rubocop:disable Layout/IndentationWidth
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer
  # available discard_on ActiveJob::DeserializationError

  # Should be used to indicate explicit retries to ActiveJob or
  # the job backend such as sidekiq. This error is ignored by e.g.
  # Sentry.
  class Retry < StandardError; end
end
end
