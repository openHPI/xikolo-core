# frozen_string_literal: true

FactoryBot.define do
  factory 'quiz:quiz', class: Hash do
    id { generate(:quiz_id) }
    instructions { 'Please do not make mistakes, that helps.' }
    max_points { 10.0 }

    trait :exam do
      current_unlimited_attempts { false }
      current_allowed_attempts { 1 }
      current_unlimited_time { false }
      current_time_limit_seconds { 3600 }
    end

    initialize_with { attributes.as_json }
  end

  factory 'quiz:question', class: Hash do
    id { generate(:question_id) }
    quiz_id
    instructions { 'Please do not make mistakes, that helps.' }
    text { 'What is the answer?' }
    points { 2.0 }

    trait :multi_select do
      type { 'Xikolo::Quiz::MultipleAnswerQuestion' }
    end

    trait :free_text do
      type { 'Xikolo::Quiz::FreeTextQuestion' }
    end

    initialize_with { attributes.as_json }
  end

  factory 'quiz:answer', class: Hash do
    id { SecureRandom.uuid }
    question_id
    text { 'Sample answer option.' }
    correct { false }

    trait :free_text do
      type { 'Xikolo::Quiz::FreeTextAnswer' }
      text { 'right' }
      correct { true }
    end

    initialize_with { attributes.as_json }
  end

  factory 'quiz:submission', class: Hash do
    id { SecureRandom.uuid }
    course_id
    quiz_id
    user_id
    points { 10.0 }
    fudge_points { 0.0 }
    vendor_data { {} }

    initialize_with { attributes.as_json }
  end

  factory 'quiz:submission_question', class: Hash do
    id { SecureRandom.uuid }
    quiz_submission_id { SecureRandom.uuid }
    quiz_question_id { SecureRandom.uuid }
    points { 10.0 }

    initialize_with { attributes.as_json }
  end

  factory 'quiz:submission_answer', class: Hash do
    id { SecureRandom.uuid }
    quiz_submission_question_id { SecureRandom.uuid }
    quiz_answer_id { SecureRandom.uuid }

    initialize_with { attributes.as_json }
  end
end
