# frozen_string_literal: true

FactoryBot.define do
  factory 'quiz:root', class: Hash do
    quizzes_url { '/quizzes' }
    quiz_url { '/quizzes/{id}' }
    questions_url { '/questions' }
    answers_url { '/answers' }

    quiz_submissions_url { '/quiz_submissions' }
    quiz_submission_url { '/quiz_submissions/{id}' }
    quiz_submission_snapshots_url { '/quiz_submission_snapshots' }
    quiz_submission_snapshot_url { '/quiz_submission_snapshots/{id}' }
    user_quiz_attempts_url { '/user_quiz_attempts' }

    initialize_with { attributes.as_json }
  end

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

    # No violations at all!
    trait :proctoring_smowl_v1_passed do
      vendor_data do
        {
          'proctoring_smowl' => {
            'black' => '0', 'cheat' => '0', 'covered' => '0',
            'discarted' => '0', 'morepeople' => '0', 'nobody' => '0', 'othertab' => '0',
            'wrongimage' => '0', 'wronguser' => '0'
          },
        }
      end
    end

    trait :proctoring_smowl_v2_pending do
      vendor_data do
        {
          'proctoring' => 'smowl_v2',
        }
      end
    end

    trait :proctoring_smowl_v2_passed do
      vendor_data do
        {
          'proctoring' => 'smowl_v2',
          'proctoring_smowl_v2' => {
            'nobodyinthepicture' => 0, 'wronguser' => 0, 'severalpeople' => 0,
            'webcamcovered' => 0, 'invalidconditions' => 0,
            'webcamdiscarted' => 0, 'notallowedelement' => 0, 'nocam' => 0,
            'otherappblockingthecam' => 0, 'notsupportedbrowser' => 0,
            'othertab' => 0, 'emptyimage' => 0, 'suspicious' => 0
          },
        }
      end
    end

    # Some violations detected, but not enough to fail
    trait :proctoring_smowl_v1_passed_with_violations do
      vendor_data do
        {
          'proctoring_smowl' => {
            'black' => '1', 'cheat' => '0', 'covered' => '0',
            'discarted' => '2', 'morepeople' => '0', 'nobody' => '0', 'othertab' => '0',
            'wrongimage' => '0', 'wronguser' => '0'
          },
        }
      end
    end

    trait :proctoring_smowl_v2_passed_with_violations do
      vendor_data do
        {
          'proctoring' => 'smowl_v2',
          'proctoring_smowl_v2' => {
            'nobodyinthepicture' => 0, 'wronguser' => 0, 'severalpeople' => 0,
            'webcamcovered' => 0, 'invalidconditions' => 0,
            'webcamdiscarted' => 0, 'notallowedelement' => 0, 'nocam' => 1,
            'otherappblockingthecam' => 0, 'notsupportedbrowser' => 0,
            'othertab' => 2, 'emptyimage' => 0, 'suspicious' => 0
          },
        }
      end
    end

    # Failed because of too many violations
    trait :proctoring_smowl_v1_failed do
      vendor_data do
        {
          'proctoring_smowl' => {
            'black' => '22', 'cheat' => '0', 'covered' => '0',
            'discarted' => '3', 'morepeople' => '0', 'nobody' => '0', 'othertab' => '0',
            'wrongimage' => '0', 'wronguser' => '0'
          },
        }
      end
    end

    trait :proctoring_smowl_v2_failed do
      vendor_data do
        {
          'proctoring' => 'smowl_v2',
          'proctoring_smowl_v2' => {
            'nobodyinthepicture' => 0, 'wronguser' => 0, 'severalpeople' => 0,
            'webcamcovered' => 0, 'invalidconditions' => 0,
            'webcamdiscarted' => 0, 'notallowedelement' => 0, 'nocam' => 22,
            'otherappblockingthecam' => 0, 'notsupportedbrowser' => 0,
            'othertab' => 3, 'emptyimage' => 0, 'suspicious' => 0
          },
        }
      end
    end

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
