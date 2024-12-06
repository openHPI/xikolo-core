# frozen_string_literal: true

FactoryBot.define do
  factory :participant do
    expertise { nil }
    user_id { SecureRandom.uuid }
    association :peer_assessment, strategy: :create
  end
end
