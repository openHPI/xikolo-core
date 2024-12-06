# frozen_string_literal: true

FactoryBot.define do
  factory :resource_pool do
    association(:peer_assessment, strategy: :create)
    purpose { 'review' }
  end
end
