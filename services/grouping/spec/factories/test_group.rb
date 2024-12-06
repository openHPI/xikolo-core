# frozen_string_literal: true

FactoryBot.define do
  factory :test_group do
    index { 0 }
    association(:user_test, strategy: :create)
    sequence(:flippers) {|i| ["new_pinboard.variant_#{i}"] }

    factory :test_group_1 do
      index { 0 }
    end

    factory :test_group_2 do
      index { 1 }
    end

    factory :test_group_w_user_test do
      index { 1 }
    end

    factory :test_group_w_waiting do
      association :user_test, factory: :user_test_with_waiting_metric

      factory :test_group_w_waiting_seq do
        association :user_test, factory: :user_test_with_waiting_metric
        sequence(:index) {|n| n }
      end
    end

    factory :test_group_w_trials_waiting do
      association :user_test, factory: :user_test_with_waiting_metric
      after :create do |test_group|
        4.times do
          test_group.trials << FactoryBot.create(:trial_waiting,
            user_id: SecureRandom.uuid,
            test_group:,
            user_test: test_group.user_test)
        end

        6.times do
          test_group.trials << FactoryBot.create(:trial_immediate,
            user_id: SecureRandom.uuid,
            test_group:,
            user_test: test_group.user_test)
        end
      end
    end

    factory :test_group_w_trials do
      association :user_test, factory: :user_test_with_waiting_metric
      after :create do |test_group|
        4.times do
          test_group.trials << FactoryBot.create(:trial_with_waiting_metric,
            user_id: SecureRandom.uuid,
            test_group:,
            user_test: test_group.user_test)
        end

        6.times do
          test_group.trials << FactoryBot.create(:trial_immediate,
            user_id: SecureRandom.uuid,
            test_group:,
            user_test: test_group.user_test)
        end
      end
    end

    factory :test_group_w_trials_w_results do
      association :user_test, factory: :user_test_with_waiting_metric
      after :create do |test_group|
        2.times do |n|
          trial = n == 0 ? :trial_w_result : :trial_w_result_3
          times = n == 0 ? 2 : 5
          times.times do
            test_group.trials << FactoryBot.create(trial,
              user_id: SecureRandom.uuid,
              test_group:,
              user_test: test_group.user_test)
          end
        end

        # 2.times do |n|
        #  trial = n == 0 ? :trial_w_result_2 : :trial_w_result_4
        #  times = n == 4 ? 4 : 6
        #  times.times do
        #    test_group.trials << FactoryBot.create(trial,
        #                                            test_group: test_group,
        #                                            user_test: test_group.user_test)
        #  end
        # end
      end
    end

    factory :test_group_w_trials_w_results_2 do
      association :user_test, factory: :user_test_with_waiting_metric
      after :create do |test_group|
        2.times do |n|
          trial = n == 0 ? :trial_w_result_2 : :trial_w_result_4
          times = n == 0 ? 5 : 3
          times.times do
            test_group.trials << FactoryBot.create(trial,
              user_id: SecureRandom.uuid,
              test_group:,
              user_test: test_group.user_test)
          end
        end
        # puts 'after :create', test_group.results

        # 2.times do |n|
        #  trial = n == 0 ? :trial_w_result_2 : :trial_w_result_4
        #  times = n == 0 ? 2 : 6
        #  times.times do
        #    test_group.trials << FactoryBot.create(trial,
        #                                            test_group: test_group,
        #                                            user_test: test_group.user_test)
        #  end
        # end
        # puts 'after :create', test_group.results
      end
    end
  end
end
