# frozen_string_literal: true

class TimeEffortJob < ApplicationRecord
  self.table_name = :time_effort_jobs

  require 'errors'
  require 'operation'

  belongs_to :item

  scope :active_for,
    ->(item) { where(item_id: item, status: %w[started waiting]) }

  default_scope { order(updated_at: :desc) }

  before_create ->(job) { TimeEffortJob.cancel_active_jobs(job.item_id) }

  class << self
    def cancel_active_jobs(item_id)
      TimeEffortJob.active_for(item_id).find_each(&:cancel)
    end
  end

  def schedule
    job = CalculateTimeEffortJob.perform_later(id)
    update!(job_id: job.job_id)
  end

  def start
    update!(status: 'started') unless cancelled?
  end

  def cancel
    return if cancelled?

    update!(status: 'cancelled')
    if CalculateTimeEffortJob.cancel(job_id)
      log_cancelled_info
      destroy
    else
      log_not_cancelled_info
    end
  end

  def cancelled?
    status == 'cancelled'
  end

  def calculation_processor
    item.processor
  end

  private

  def log_cancelled_info
    Sidekiq.logger.info do
      "Cancelled enqueued CalculateTimeEffortJob (id: #{job_id}) " \
        "belonging to TimeEffortJob (id: #{id})"
    end
  end

  def log_not_cancelled_info
    Sidekiq.logger.info do
      "Could not cancel enqueued CalculateTimeEffortJob (id: #{job_id}) " \
        "belonging to TimeEffortJob (id: #{id})"
    end
  end
end
