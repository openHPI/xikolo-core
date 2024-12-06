# frozen_string_literal: true

FactoryBot.define do
  factory :answer do
    association :question, factory: :multiple_answer_question
    comment { 'This is the correct answer, well done.' }
    position { 10 }
    correct { true }

    factory :text_answer, parent: :answer do
      type { 'TextAnswer' }
    end

    factory :free_text_answer, parent: :answer do
      association :question, factory: :free_text_question
      type { 'FreeTextAnswer' }
    end
  end
end
