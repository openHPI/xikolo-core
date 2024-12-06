# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :commentable, factory: :question, strategy: :create

    text { 'Eine FANTASTISCHE Frage! Sollte mehr von der Sorte geben :)' }
    user_id { '00000001-3100-4444-9999-000000000003' }
    deleted { false }

    trait :for_answer do
      association :commentable, factory: :answer
    end

    factory :technical_comment do
      association :commentable, factory: :technical_question
    end
  end
end
