# frozen_string_literal: true

FactoryBot.define do
  factory :user_test do
    name { 'Pink background' }
    sequence(:identifier) {|n| "pink_background_#{n}" }
    description { 'Show pink background' }
    round_robin { false }
    round_robin_counter { 0 }
    start_date { 2.days.ago }
    end_date { 5.days.from_now }
    after :create do |user_test|
      user_test.metrics << create(:enrollments_metric)
    end

    trait :round_robin do
      round_robin { true }
    end

    factory :user_test_w_test_groups do
      sequence(:identifier) {|n| "pink_background_w_groups_#{n}" }
      round_robin
      after :create do |user_test|
        user_test.metrics.first.update_attribute :distribution, 'normal' # rubocop:disable Rails/SkipsModelValidations
        user_test.test_groups << FactoryBot.create(:test_group_1, user_test:, flippers: ['nudging.variant_1'])
        user_test.test_groups << FactoryBot.create(:test_group_2, user_test:, flippers: ['nudging.variant_2'])
      end
    end

    factory :user_test_with_waiting_metric do
      sequence(:identifier) {|n| "pink_background_w_waiting_metric_#{n}" }
      after :create do |user_test|
        user_test.metrics << create(:enrollments_metric, :waiting)
      end

      factory :user_test_w_waiting_metric_and_results_trials_waiting do
        sequence(:identifier) {|n| "user_test_w_waiting_metric_and_results_#{n}" }
        after :create do |user_test|
          user_test.test_groups << create(:test_group_w_trials_waiting, user_test:)
        end
      end

      factory :user_test_w_waiting_metric_and_results do
        sequence(:identifier) {|n| "user_test_w_waiting_metric_and_results_#{n}" }
        after :create do |user_test|
          user_test.test_groups << create(:test_group_w_trials, user_test:)
        end
      end

      factory :user_test_two_groups do
        sequence(:identifier) {|n| "user_test_w_waiting_metric_and_results_#{n}" }
        after :create do |user_test|
          user_test.test_groups << create(:test_group_w_trials, user_test:, index: 0)
          user_test.test_groups << create(:test_group_w_trials, user_test:, index: 1)
        end
      end

      factory :user_test_two_groups_finished do
        sequence(:identifier) {|n| "user_test_two_groups_finished_#{n}" }
        end_date { 1.day.ago }
        after :create do |user_test|
          user_test.metrics.find_by(wait: false).update_attribute :distribution, 'normal' # rubocop:disable Rails/SkipsModelValidations
          user_test.test_groups << create(:test_group_w_trials_w_results,
            user_test:, index: 0)
          user_test.test_groups << create(:test_group_w_trials_w_results_2, user_test:, index: 1)
        end
      end
    end

    factory :user_test_with_filter do
      after :create do |user_test|
        user_test.filters << create(:filter)
      end
    end
  end
end
