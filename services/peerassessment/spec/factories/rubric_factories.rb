# frozen_string_literal: true

FactoryBot.define do
  factory :rubric do
    hints { 'Lorem Ipsum Hints' }
    title { 'Lorem Ipsum Title' }
    association :peer_assessment, strategy: :create

    trait :with_random_options do
      after(:create) do |rubric|
        Random.rand(1..4).times do |i|
          rubric.rubric_options.create(points: i + 1)
        end
      end
    end

    trait :with_deterministic_options do
      after(:create) do |rubric|
        3.times do |i|
          rubric.rubric_options.create(points: i + 1)
        end
      end
    end

    trait :with_many_deterministic_options do
      after(:create) do |rubric|
        6.times do |i|
          rubric.rubric_options.create(points: i + 1)
        end
      end
    end

    trait :with_options_that_provide_identical_points do
      after(:create) do |rubric|
        6.times do |_i|
          rubric.rubric_options.create(points: 20)
        end
      end
    end
  end
end
