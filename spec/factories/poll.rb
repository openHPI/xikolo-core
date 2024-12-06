# frozen_string_literal: true

FactoryBot.define do
  factory :poll, class: 'Poll::Poll' do
    question { 'What do you think about our platform?' }
    show_intermediate_results { true }
    allow_multiple_choices { false }

    trait :multiple_choice do
      allow_multiple_choices { true }
    end

    trait :current do
      start_at { 3.days.ago }
      end_at { 3.days.from_now }
    end

    trait :past do
      start_at { 2.weeks.ago }
      end_at { 1.week.ago }
    end

    trait :future do
      start_at { 1.week.from_now }
      end_at { 2.weeks.from_now }
    end

    transient do
      option_count { 3 }
      option_texts { [] }
      response_count { 0 }
    end

    trait :with_responses do
      transient do
        response_count { 2 }
      end
    end

    trait :with_sufficient_response_count do
      transient do
        response_count { 21 }
      end
    end

    after(:create) do |poll, evaluator|
      if evaluator.option_texts.any?
        evaluator.option_texts.each {|text| create(:poll_option, poll:, text:) }
      else
        create_list(:poll_option, evaluator.option_count, poll:)
      end

      create_list(:poll_response, evaluator.response_count, poll:)
    end
  end

  factory :poll_option, class: 'Poll::Option' do
    sequence(:text) {|i| "I like it #{i} times" }
    sequence(:position) {|i| i }
    association :poll, :current
  end

  factory :poll_response, class: 'Poll::Response' do
    association :poll, :current
    user_id
    choices { [poll.options.first.id] }
  end
end
