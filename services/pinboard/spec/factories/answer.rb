# frozen_string_literal: true

FactoryBot.define do
  factory :answer do
    text { 'SQL stands for Structured Query Language.' }
    association :question
    user_id { '00000001-3100-4444-9999-000000000002' }

    factory :technical_answer do
      association :question, factory: :technical_question
    end

    factory :answer_with_comment do
      after(:create) do |answer|
        create(:comment, commentable: answer, commentable_type: 'Answer')
      end
    end
  end
end
