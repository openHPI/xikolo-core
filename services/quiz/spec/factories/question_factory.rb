# frozen_string_literal: true

FactoryBot.define do
  trait :base_question do
    association :quiz
    points { 10.0 }
    shuffle_answers { false }
    exclude_from_recap { false }
  end

  factory :multiple_choice_question do
    type { 'MultipleChoiceQuestion' }
    base_question
  end

  factory :multiple_answer_question do
    type { 'MultipleAnswerQuestion' }
    base_question
  end

  factory :free_text_question do
    type { 'FreeTextQuestion' }
    base_question
  end

  factory :essay_question do
    type { 'EssayQuestion' }
    base_question
  end
end
