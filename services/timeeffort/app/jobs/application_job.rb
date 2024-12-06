# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  before_perform ->(job) { detailed_log('Starting', job) }
  after_perform ->(job) { detailed_log('Finished', job) }

  private

  def detailed_log(action, job)
    Sidekiq.logger.info "#{action} #{job.class} (id: #{job.job_id})"
  end
end
