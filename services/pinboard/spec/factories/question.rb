# frozen_string_literal: true

FactoryBot.define do
  factory :'pinboard_service/question', class: 'Question' do
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
        create_list(:'pinboard_service/subscription', evaluator.subscription_count, question:)
      end
    end

    trait :with_comment do
      after(:create) do |question|
        create(:'pinboard_service/comment', commentable: question, commentable_type: 'Question')
      end
    end

    trait :with_commented_answer do
      after(:create) do |question|
        create(:'pinboard_service/answer_with_comment', question:)
      end
    end

    factory :'pinboard_service/question_with_tags', class: 'Question' do
      tags { [FactoryBot.create(:'pinboard_service/sql_tag'), FactoryBot.create(:'pinboard_service/definition_tag')] }
    end

    factory :'pinboard_service/question_with_definition_tag', class: 'Question' do
      tags { [FactoryBot.create(:'pinboard_service/definition_tag')] }
    end

    factory :'pinboard_service/question_with_implicit_tags', class: 'Question' do
      tags do
        [FactoryBot.create(:'pinboard_service/sql_tag'),
         FactoryBot.create(:'pinboard_service/section_tag'), FactoryBot.create(:'pinboard_service/video_item_tag')]
      end
    end

    factory :'pinboard_service/unvoted_uncommented_question', class: 'Question' do
      user_id { '00000001-3100-4444-9999-000000000002' }
      title { 'Seriously guys...' }
      text { "Who is this Batman and why doesn't he wear proper weapons?" }
      video_id { '00000001-3600-4444-9999-000000000002' }
    end

    factory :'pinboard_service/deleted_question', class: 'Question' do
      deleted { true }
    end

    factory :'pinboard_service/question_with_vote', class: 'Question' do
      after(:create) do |question|
        create(:'pinboard_service/vote', votable: question, votable_type: 'Question')
      end
    end

    factory :'pinboard_service/question_with_accepted_answer', class: 'Question' do
      after(:create) do |question|
        answer = create(:'pinboard_service/answer', question:)
        question.accepted_answer = answer
        question.save
      end
    end

    factory :'pinboard_service/question_with_comment', traits: [:with_comment], class: 'Question'

    factory :'pinboard_service/question_with_commented_answer', traits: [:with_commented_answer], class: 'Question'

    factory :'pinboard_service/technical_question', class: 'Question' do
      title { 'Technical Question' }
      tags { [FactoryBot.create(:'pinboard_service/technical_issues_tag')] }
    end

    factory :'pinboard_service/video_question', class: 'Question' do
      sequence(:title) {|n| "Video Question #{n}" }
      tags { [FactoryBot.create(:'pinboard_service/video_item_tag')] }

      trait :with_timestamp do
        video_timestamp { 12_345 }
      end
    end
  end
end
