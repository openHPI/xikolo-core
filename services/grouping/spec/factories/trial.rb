# frozen_string_literal: true

FactoryBot.define do
  factory :trial do
    user_id { '00000001-3100-4444-9999-000000000003' }
    finished { false }
    association(:test_group, strategy: :create)
    user_test { test_group.user_test }

    factory :trial_with_waiting_metric do
      association :test_group, factory: :test_group_w_waiting

      factory :trial_waiting do
        finished { true }
        after :create do |trial|
          waiting_metric = trial.user_test.metrics.find_by('wait_interval > 0')
          trial.trial_results.find_by(metric: waiting_metric).update!(waiting: true)
        end
      end

      factory :trial_waiting_w_waiting_results do
        finished { true }
        after :create do |trial|
          waiting_metric = trial.user_test.metrics.find_by('wait_interval > 0')
          trial.trial_results.find_by(metric: waiting_metric).update!(waiting: true)
        end
      end
    end

    factory :trial_immediate do
      finished { true }
      after :create do |trial|
        metric = trial.user_test.metrics.find_by(wait_interval: 0)
        trial.trial_results.find_by(metric:).update!(result: 1)
      end
    end

    factory :trial_w_result do
      finished { true }
      after :create do |trial|
        metric = trial.user_test.metrics.find_by(wait_interval: 0)
        trial.trial_results.find_by(metric:).update!(result: 1)
        metric = trial.user_test.metrics.find_by('wait_interval > 0')
        trial.trial_results.find_by(metric:).update!(result: 2)
      end
    end

    factory :trial_w_result_2 do
      finished { true }
      after :create do |trial|
        metric = trial.user_test.metrics.find_by(wait_interval: 0)
        trial.trial_results.find_by(metric:).update!(result: 2)
        metric = trial.user_test.metrics.find_by('wait_interval > 0')
        trial.trial_results.find_by(metric:).update!(result: 3)
      end
    end

    factory :trial_w_result_3 do
      finished { true }
      after :create do |trial|
        metric = trial.user_test.metrics.find_by(wait_interval: 0)
        trial.trial_results.find_by(metric:).update!(result: 3)
        metric = trial.user_test.metrics.find_by('wait_interval > 0')
        trial.trial_results.find_by(metric:).update!(result: 4)
      end
    end

    factory :trial_w_result_4 do
      finished { true }
      after :create do |trial|
        metric = trial.user_test.metrics.find_by(wait_interval: 0)
        trial.trial_results.find_by(metric:).update!(result: 5)
        metric = trial.user_test.metrics.find_by('wait_interval > 0')
        trial.trial_results.find_by(metric:).update!(result: 4)
      end
    end
  end
end
