# frozen_string_literal: true

# Wisper.subscribe(TestGroupListener.new) do
#   user_test = UserTest.create! name: 'Pink background',
#                                identifier: 'pink_background',
#                                description: 'Show pink background',
#                                start_date: 2.days.ago,
#                                end_date: 5.days.from_now,
#                                course_id: '00000001-3300-4444-9999-000000000002'
#   user_test.metrics << Metrics::EnrollmentsMetric.create!
#
#   test_group_1 = user_test.test_groups.create! index: 0, name: 'Gray background'
#   test_group_2 = user_test.test_groups.create! index: 1, name: 'Pink background'
#
#   200.times do
#     trial = Trial.create! user_id: SecureRandom.uuid,
#                           user_test: user_test,
#                           test_group: test_group_1,
#                           finished: true
#
#     trial.trial_results.find_by(metric: user_test.metrics.first)
#       .update! result: rand(2)
#   end
#
#   199.times do
#     trial = Trial.create! user_id: SecureRandom.uuid,
#                           user_test: user_test,
#                           test_group: test_group_2,
#                           finished: true
#
#     trial.trial_results.find_by(metric: user_test.metrics.first)
#       .update! result: (rand + 0.6).to_i
#   end
# end
