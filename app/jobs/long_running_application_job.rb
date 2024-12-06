# frozen_string_literal: true

class LongRunningApplicationJob < ApplicationJob
  queue_as 'long_running'

  # The max amount of time a job is allowed to run before it is stopped.
  # Must be less than the global `max_run_time` default,
  # see config/initializers/delayed.rb.
  # Long-running jobs are allowed to run for 10 hours, which is the globally
  # configured maximum runtime.
  def max_run_time
    10.hours
  end

  def max_attempts
    5
  end
end
