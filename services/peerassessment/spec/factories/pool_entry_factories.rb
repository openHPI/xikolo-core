# frozen_string_literal: true

FactoryBot.define do
  factory :pool_entry do
    priority { 0 }
    available_locks { 1 }
    association(:submission, strategy: :create)
    association(:resource_pool, strategy: :create)
  end
end
