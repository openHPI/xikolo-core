# frozen_string_literal: true

FactoryBot.define do
  factory :'quiz_service/quiz' do
    time_limit_seconds { 3600 }
    unlimited_time { false }
    allowed_attempts { 1 }
    unlimited_attempts { false }
    question_pool { false }
    external_ref_id { 'Some_External_Ref' }

    trait :unlimited_time do
      unlimited_time { true }
    end

    trait :with_valid_question_pool do
      question_pool { true }
      displayed_question_count { 10 }
      instructions { 'This is a instruction text' }

      after(:create) do |quiz|
        question_number = 0
        [[10, 1], [10, 2], [10, 3]].each do |count, points|
          count.times do
            question_number += 1
            create(:'quiz_service/multiple_choice_question',
              quiz:,
              text: "Pool question [#{question_number}]",
              points:,
              shuffle_answers: false)
          end
        end
      end
    end

    trait :with_question_pool do
      with_valid_question_pool

      after(:create) do |quiz|
        quiz.questions.order(:created_at).each do |question|
          question_number = question.text[/\d+/]
          create(:'quiz_service/text_answer',
            question:,
            text: "Correct answer for Pool question [#{question_number}]",
            correct: true,
            position: 1)
          create(:'quiz_service/text_answer',
            question:,
            text: "Incorrect answer for Pool question [#{question_number}]",
            correct: false,
            position: 2)
        end
      end
    end
  end
end
