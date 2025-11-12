# frozen_string_literal: true

module PinboardService
class ApplicationJob < ActiveJob::Base # rubocop:disable Layout/IndentationWidth
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
end
