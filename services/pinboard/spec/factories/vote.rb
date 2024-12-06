# frozen_string_literal: true

FactoryBot.define do
  factory :vote do
    value { 1 }
    association :votable, factory: :question
    votable_type { 'Question' }
    sequence(:user_id, 1000) {|n| "00000001-3100-4444-9999-00000000#{n}" }
  end

  trait :for_answer do
    association :votable, factory: :answer
    votable_type { 'Answer' }
  end
end
