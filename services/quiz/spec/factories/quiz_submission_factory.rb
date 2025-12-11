# frozen_string_literal: true

FactoryBot.define do
  factory :'quiz_service/quiz_submission' do
    association :quiz, factory: :'quiz_service/quiz'
    user_id { '00000000-0000-4444-9999-000000000001' }
    quiz_submission_time { nil }

    trait :submitted do
      quiz_submission_time { 1.hour.ago }
    end
  end
end
