# frozen_string_literal: true

class TrialResult < ApplicationRecord
  include Wisper::Publisher

  belongs_to :trial
  belongs_to :metric, class_name: '::Metrics::Metric'
  validates :metric_id, uniqueness: {scope: :trial_id}

  delegate :user_test, to: :trial
  delegate :test_group, to: :trial
  delegate :user_id, to: :trial
  delegate :finish_time, to: :trial
  delegate :course_id, to: :user_test

  scope :waiting, -> { where(waiting: true) }
  scope :with_result, -> { where.not(result: nil) }
  scope :for_user_test, lambda {|user_test|
    joins(trial: :user_test).where(
      trials: {user_test_id: user_test.id}
    )
  }
  scope :for_test_group, lambda {|test_group|
    joins(trial: :test_group).where(
      trials: {test_group_id: test_group.id}
    )
  }

  after_update {|trial_result| publish(:trial_result_changed, trial_result) }

  def delayed_metric?
    metric.delayed?
  end

  def metric_end_time
    trial.finish_time + metric.wait_interval unless trial.finish_time.nil?
  end

  def self.csv_headers
    [
      *column_names - %w[metric_id trial_id],
      'metric',
      'user_id',
      'test_group',
    ].join ','
  end

  def to_csv
    decorate.as_csv
  end
end
