# frozen_string_literal: true

FactoryBot.define do
  factory 'gamification:root', class: Hash do
    badges_url { '/badges' }
    scores_url { '/scores' }
    score_url { '/scores{/id}' }

    initialize_with { attributes.as_json }
  end

  factory :gamification_badge, class: 'Gamification::Badge' do
    user
    name { 'communicator' }
    level { 1 }

    trait :bronze do
      level { 0 }
    end

    trait :silver do
      level { 1 }
    end

    trait :gold do
      level { 2 }
    end
  end

  factory :gamification_score, class: 'Gamification::Score' do
    user
    course
    rule { 'test_rule' }
    sequence(:checksum, &:to_s)
    points { 5 }

    trait :question_create do
      rule { 'create_question' }
      points { 0 }
      data { {question_id: generate(:uuid).to_s} }

      checksum { data[:question_id] }
    end

    trait :answer_create do
      rule { 'answered_question' }
      points { 1 }
      data { {answer_id: generate(:uuid).to_s} }

      checksum { data[:answer_id] }
    end

    trait :comment_create do
      rule { 'create_comment' }
      points { 0 }
      data { {comment_id: generate(:uuid).to_s} }

      checksum { data[:comment_id] }
    end

    trait :question_vote do
      rule { 'upvote_question' }
      points { 5 }
      data { {votable_id: generate(:uuid).to_s} }

      checksum { data[:votable_id] }
    end

    trait :answer_vote do
      rule { 'upvote_answer' }
      points { 10 }
      data { {votable_id: generate(:uuid).to_s} }

      checksum { data[:votable_id] }
    end

    trait :accepted_answer do
      rule { 'accepted_answer' }
      points { 30 }
      data { {accepted_answer_id: generate(:uuid).to_s} }

      checksum { data[:accepted_answer_id] }
    end

    trait :visit_create do
      rule { 'visited_item' }
      points { 0 }
      data do
        {
          visit_id: generate(:uuid).to_s,
          item_id: generate(:uuid).to_s,
          section_id: generate(:uuid).to_s,
        }
      end

      checksum { data[:visit_id] }
    end

    trait :take_selftest do
      rule { 'take_selftest' }
      points { 0 }
      data do
        {
          result_id: generate(:uuid).to_s,
          item_id: generate(:uuid).to_s,
          section_id: generate(:uuid).to_s,
        }
      end

      checksum { data[:result_id] }
    end

    trait :selftest_master do
      rule { 'selftest_master' }
      points { 2 }
      data do
        {
          result_id: generate(:uuid).to_s,
          item_id: generate(:uuid).to_s,
          section_id: generate(:uuid).to_s,
        }
      end

      checksum { data[:result_id] }
    end

    trait :take_exam do
      rule { 'take_exam' }
      points { 0 }
      data do
        {
          result_id: generate(:uuid).to_s,
          item_id: generate(:uuid).to_s,
          section_id: generate(:uuid).to_s,
        }
      end

      checksum { data[:result_id] }
    end

    trait :attended_section do
      rule { 'attended_section' }
      points { 0 }
      data { {section_id: generate(:uuid).to_s} }

      checksum { data[:section_id] }
    end

    trait :continuous_attendance do
      rule { 'continuous_attendance' }
      points { 10 }
      data { {section_id: generate(:uuid).to_s} }

      checksum { data[:section_id] }
    end
  end
end
