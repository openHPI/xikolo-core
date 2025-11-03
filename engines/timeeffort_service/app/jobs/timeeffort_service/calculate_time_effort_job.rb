# frozen_string_literal: true

module TimeeffortService
class CalculateTimeEffortJob < ApplicationJob # rubocop:disable Layout/IndentationWidth
  require 'errors'

  queue_as :default

  after_perform :remove_time_effort_job_record

  attr_reader :time_effort_job

  def perform(job_id)
    @time_effort_job = TimeEffortJob.find job_id
    time_effort_job.reload.start

    return unless time_effort_job.reload_item

    processor = time_effort_job.calculation_processor

    check_job_status!
    processor.load_resources!

    check_job_status!
    processor.calculate

    check_job_status!
    processor.patch_items!
  rescue ActiveRecord::RecordNotFound,
         Errors::LoadResourcesError
  # Skip/exit execution if the TimeEffortJob or the associated
  # content resource does not exist (anymore).
  rescue Errors::TimeEffortJobCancelled
    Sidekiq.logger.info 'Cancelled execution of CalculateTimeEffortJob ' \
                        "(id: #{time_effort_job.job_id}) belonging to TimeEffortJob " \
                        "(id: #{time_effort_job.id})."
  end

  private

  def check_job_status!
    raise Errors::TimeEffortJobCancelled if time_effort_job.reload.cancelled?
  end

  def remove_time_effort_job_record
    time_effort_job.destroy
  rescue NoMethodError
    Sidekiq.logger.error 'Tried to delete not existing TimeEffortJob ' \
                         'after the job was performed.'
  end
end
end
