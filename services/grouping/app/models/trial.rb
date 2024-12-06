# frozen_string_literal: true

class Trial < ApplicationRecord
  belongs_to :user_test, -> { includes :metrics }
  belongs_to :test_group, counter_cache: true
  has_many :trial_results, dependent: :delete_all

  scope :finished, -> { where(finished: true) }

  after_create :create_trial_results
  after_update :handle_finished_changed, if: :saved_change_to_finished?

  def create_trial_results
    user_test.reload.metrics.each do |metric|
      trial_results.create metric:
    end
  end

  def handle_finished_changed
    return if finish_time.present?

    update_columns(finish_time: Time.current, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    trial_results.includes(:metric).find_each do |trial_result|
      if trial_result.delayed_metric?
        create_fetch_job trial_result
      else
        fetch_result trial_result
      end
    end
  end

  def fetch_result(trial_result)
    TrialResultWorker.perform_async trial_result.id, finished
  end

  def create_fetch_job(result)
    result.update! waiting: true
    expected_runtime = result.created_at + result.metric.wait_interval
    # update values every hour
    unless expected_runtime.future?
      expected_runtime -= 1.hour
      if expected_runtime.future?
        TrialResultWorker.perform_at expected_runtime, result.id, false
      end
    end
    TrialResultWorker.perform_at(
      result.created_at + result.metric.wait_interval, result.id, true
    )
  end
end
