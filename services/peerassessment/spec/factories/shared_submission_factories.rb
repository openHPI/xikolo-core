# frozen_string_literal: true

FactoryBot.define do
  factory :shared_submission do
    text { 'This is a submission' }
    submitted { false }
    disallowed_sample { false }
    gallery_opt_out { false }
    attachments { [] }
    association :peer_assessment

    trait :as_submitted do
      submitted { true }
    end
  end
end
