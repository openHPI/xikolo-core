# frozen_string_literal: true

FactoryBot.define do
  factory :group do
    trait :with_participants do
      after(:create) do |group|
        group.participants << FactoryBot.create_list(:participant, 5, peer_assessment: create(:peer_assessment))
      end
    end
  end
end
