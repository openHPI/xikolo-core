# frozen_string_literal: true

FactoryBot.define do
  factory :question do
    user_id { '00000001-3100-4444-9999-000000000001' }
    sequence(:title) {|n| "Test Title #{n}" }
    text { 'SQL seems to be an abbreviation. Does anyone know its meaning?' }
    video_id { '00000001-3600-4444-9999-000000000001' }
    course_id { '00000001-3300-4444-9999-000000000001' }
    deleted { false }

    trait :with_subscriptions do
      transient do
        subscription_count { 5 }
      end

      after(:create) do |question, evaluator|
        create_list(:subscription, evaluator.subscription_count, question:)
      end
    end

    trait :with_comment do
      after(:create) do |question|
        create(:comment, commentable: question, commentable_type: 'Question')
      end
    end

    trait :with_commented_answer do
      after(:create) do |question|
        create(:answer_with_comment, question:)
      end
    end

    factory :question_with_tags do
      tags { [FactoryBot.create(:sql_tag), FactoryBot.create(:definition_tag)] }
    end

    factory :question_with_definition_tag do
      tags { [FactoryBot.create(:definition_tag)] }
    end

    factory :question_with_implicit_tags do
      tags do
        [FactoryBot.create(:sql_tag),
         FactoryBot.create(:section_tag), FactoryBot.create(:video_item_tag)]
      end
    end

    factory :unvoted_uncommented_question do
      user_id { '00000001-3100-4444-9999-000000000002' }
      title { 'Seriously guys...' }
      text { "Who is this Batman and why doesn't he wear proper weapons?" }
      video_id { '00000001-3600-4444-9999-000000000002' }
    end

    factory :deleted_question do
      deleted { true }
    end

    factory :question_with_vote do
      after(:create) do |question|
        create(:vote, votable: question, votable_type: 'Question')
      end
    end

    factory :question_with_accepted_answer do
      after(:create) do |question|
        answer = create(:answer, question:)
        question.accepted_answer = answer
        question.save
      end
    end

    factory :question_with_comment, traits: [:with_comment]
    factory :question_with_commented_answer, traits: [:with_commented_answer]

    factory :technical_question do
      title { 'Technical Question' }
      tags { [FactoryBot.create(:technical_issues_tag)] }
    end

    factory :video_question do
      sequence(:title) {|n| "Video Question #{n}" }
      tags { [FactoryBot.create(:video_item_tag)] }

      trait :with_timestamp do
        video_timestamp { 12_345 }
      end
    end
  end
end
