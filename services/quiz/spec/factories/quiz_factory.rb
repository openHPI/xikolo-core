# frozen_string_literal: true

FactoryBot.define do
  factory :quiz do
    time_limit_seconds { 3600 }
    unlimited_time { false }
    allowed_attempts { 1 }
    unlimited_attempts { false }
    external_ref_id { 'Some_External_Ref' }

    trait :unlimited_time do
      unlimited_time { true }
    end
  end
end
