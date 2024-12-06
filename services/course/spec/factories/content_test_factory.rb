# frozen_string_literal: true

FactoryBot.define do
  factory :content_test do
    identifier { 'human-readable-identifier-for-ui' }
    groups { %w[plain game] }

    association(:course)
  end
end
