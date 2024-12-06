# frozen_string_literal: true

FactoryBot.define do
  factory :conflict do
    reason { 'Some reason' }
    comment { 'Some comment' }
    open { true }
    reporter { SecureRandom.uuid }
    association :peer_assessment, strategy: :create
  end
end
