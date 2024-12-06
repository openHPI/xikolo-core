# frozen_string_literal: true

FactoryBot.define do
  factory :question_statistics do
    association :question, factory: :multiple_choice_question
    max_points { 10.0 }
    submission_count { 1 }
    submission_user_count { 0 }
    avg_points { 10.0 }

    trait :for_multiple_answer_question do
      association :question, factory: :multiple_answer_question
    end

    trait :for_multiple_choice_question do
      association :question, factory: :multiple_choice_question
    end

    trait :for_essay_question do
      association :question, factory: :essay_question
      answer_statistics do
        {
          avg_length: 0.0,
        }
      end
    end

    trait :for_free_text_question do
      association :question, factory: :free_text_question
      answer_statistics do
        {
          unique_answer_count: 0,
          non_unique_answer_texts: 0,
        }
      end
    end
  end
end
