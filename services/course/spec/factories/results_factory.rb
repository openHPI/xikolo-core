# frozen_string_literal: true

FactoryBot.define do
  factory :result do
    user_id
    association :item, factory: %i[item with_max_points]
    dpoints { 1 }
  end
end
