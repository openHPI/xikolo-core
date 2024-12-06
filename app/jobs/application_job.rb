# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  queue_as 'default'

  # The max amount of time a job is allowed to run before it is stopped.
  # Must be less than the global `max_run_time` default,
  # see config/initializers/delayed.rb.
  # Allow a regular job to run for 20 minutes, which is the delayed gem default.
  def max_run_time
    20.minutes
  end

  # Automatically retry jobs that encountered a deadlock.
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available.
  # discard_on ActiveJob::DeserializationError

  # Should be used to indicate explicit retries to ActiveJob.
  # This error is ignored by Sentry.
  class ExpectedRetry < StandardError; end
end
