# frozen_string_literal: true

FactoryBot.define do
  factory :gallery_vote do
    rating { 3 }
    association :shared_submission
  end
end
