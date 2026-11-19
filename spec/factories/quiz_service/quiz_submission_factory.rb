# frozen_string_literal: true

FactoryBot.define do
  factory :'quiz_service/quiz_submission' do
    association :quiz, factory: :'quiz_service/quiz'
    association :user, factory: :'account_service/user'
    quiz_submission_time { nil }

    trait :submitted do
      quiz_submission_time { 1.hour.ago }
    end
  end
end
