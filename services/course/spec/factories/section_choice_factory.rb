# frozen_string_literal: true

FactoryBot.define do
  factory :section_choice do
    association :section, :parent
    user_id { SecureRandom.uuid }
  end
end
