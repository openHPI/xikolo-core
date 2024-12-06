# frozen_string_literal: true

FactoryBot.define do
  factory 'lti:root', class: Hash do
    lti_exercises_url { '/lti_exercises' }
    lti_exercise_url { '/lti_exercises/{id}' }

    lti_gradebooks_url { '/lti_gradebooks' }
    lti_gradebook_url { '/lti_gradebooks/{id}' }

    lti_grades_url { '/lti_grades' }
    lti_grade_url { '/lti_grades/{id}' }

    lti_providers_url { '/lti_providers' }
    lti_provider_url { '/lti_providers/{id}' }

    grading_url { '/gradings/{id}' }

    initialize_with { attributes.as_json }
  end

  factory 'lti:gradebook', class: Hash do
    id { generate(:uuid) }
    lti_exercise_id { generate(:uuid) }
    user_id { generate(:uuid) }

    initialize_with { attributes.as_json }
  end

  factory 'lti:grade', class: Hash do
    id { generate(:uuid) }
    lti_gradebook_id { generate(:uuid) }
    score { 0.25 }

    initialize_with { attributes.as_json }
  end

  factory 'lti:provider', class: Hash do
    id { generate(:uuid) }
    domain { 'http://example.org/lti' }
    presentation_mode { 'window' }

    trait :iframe do
      presentation_mode { 'frame' }
    end

    initialize_with { attributes.as_json }
  end

  factory :lti_exercise, class: 'Lti::Exercise' do
    association(:provider, factory: :lti_provider)
    title { 'Exercise' }
    weight { nil }

    trait :locked do
      lock_submissions_at { 2.days.ago }
    end

    trait :with_instructions do
      instructions { 'Launch the tool and submit your results' }
    end
  end

  factory :lti_grade, class: 'Lti::Grade' do
    association(:gradebook, factory: :lti_gradebook)
    value { 1 }
    nonce { SecureRandom.hex(20) }
  end

  factory :lti_gradebook, class: 'Lti::Gradebook' do
    association(:exercise, factory: :lti_exercise)
    user_id
  end

  factory :lti_provider, class: 'Lti::Provider' do
    consumer_key { 'key' }
    domain { 'https://example.org/lti' }
    name { 'Provider' }
    presentation_mode { 'pop-up' }
    shared_secret { 'secret' }
    course_id
    privacy { 'unprotected' }

    trait :global do
      course_id { nil }
    end

    trait :iframe do
      presentation_mode { 'frame' }
    end

    trait :window do
      presentation_mode { 'window' }
    end

    trait :anonymized do
      privacy { 'anonymized' }
    end

    trait :pseudonymized do
      privacy { 'pseudonymized' }
    end

    trait :unprotected do
      privacy { 'unprotected' }
    end
  end
end
