# frozen_string_literal: true

class TrialResultWorker
  include Sidekiq::Job

  # rubocop:disable Style/OptionalBooleanParameter - keyword args not supported in Sidekiq
  # rubocop:disable Rails/SkipsModelValidations
  def perform(trial_result_id, final_calculation = true)
    ActiveRecord::Base.connection_pool.with_connection do
      trial_result = TrialResult.find trial_result_id

      # return if trial_result.result.present? and !trial_result.waiting

      TrialResult.transaction do
        trial_result.update_column :result,
          trial_result.metric.class.query(trial_result.user_id,
            trial_result.course_id,
            trial_result.finish_time,
            trial_result.metric_end_time)
        trial_result.update_column :waiting, !final_calculation
        trial_result.update_column :updated_at, Time.now.utc
      rescue StandardError
        # Maybe log something here later
      end
      trial_result.test_group.compute_statistics(trial_result.metric)
    end
  end
  # rubocop:enable all
end
