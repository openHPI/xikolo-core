# frozen_string_literal: true

FactoryBot.define do
  factory :delivery do
    association :message
    user_id { generate(:uuid) }
  end
end
