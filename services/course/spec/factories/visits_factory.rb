# frozen_string_literal: true

FactoryBot.define do
  factory :visit do
    user_id
    item
    updated_at { Time.current }
  end
end
