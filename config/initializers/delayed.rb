# frozen_string_literal: true

require 'delayed'

# A list of queues to which all work is restricted.
Delayed::Worker.queues = %w[default long_running mails]
# The max number of attempts jobs are given before they are permanently marked as failed.
Delayed::Worker.max_attempts = 25
# The max amount of time a job is allowed to run before it is stopped.
Delayed::Worker.max_run_time = 10.hours

ActiveSupport::Notifications.subscribe(/^delayed\.job\.(run|error|failure)$/) do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  job = event.payload.fetch(:job)

  Xikolo.metrics.write(
    'delayed_jobs',
    tags: {
      **event.payload.slice(:job_name, :queue),
      priority: job.priority.to_i,
      priority_name: job.priority.to_s,
      errored: job.last_error?,
      failed: job.failed?,
      retried: job.attempts > 1,
      event: event.name,
    },
    values: {
      id: job.id,
      attempts: job.attempts,
      age: job.age,
      run_time: job.run_time,
      duration: event.try(:duration),
    }
  )
end
