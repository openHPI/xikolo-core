# frozen_string_literal: true

FactoryBot.define do
  factory :watch do
    user_id { '00000001-3100-4444-9999-000000000001' }
    association :question, strategy: :create
  end
end
