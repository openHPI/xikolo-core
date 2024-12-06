# frozen_string_literal: true

FactoryBot.define do
  factory :enrollment do
    association(:course, strategy: :create)
    user_id
    deleted { false }
    forced_submission_date { nil }

    trait :reactivated do
      forced_submission_date { 6.weeks.from_now }
    end

    trait :was_reactivated do
      forced_submission_date { 2.years.ago }
    end

    factory :deleted_enrollment do
      deleted { true }
    end
  end
end
