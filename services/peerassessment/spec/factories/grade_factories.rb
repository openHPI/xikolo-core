# frozen_string_literal: true

FactoryBot.define do
  factory :grade do
    association :submission
    base_points { 3.0 }
    bonus_points { [] }
    delta { 0.0 }
    absolute { false }
  end
end
