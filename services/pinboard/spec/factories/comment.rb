# frozen_string_literal: true

FactoryBot.define do
  factory :'pinboard_service/comment', class: 'Comment' do
    association :commentable, factory: :'pinboard_service/question', strategy: :create

    text { 'Eine FANTASTISCHE Frage! Sollte mehr von der Sorte geben :)' }
    user_id { '00000001-3100-4444-9999-000000000003' }
    deleted { false }

    trait :for_answer do
      association :commentable, factory: :'pinboard_service/answer'
    end

    factory :'pinboard_service/technical_comment' do
      association :commentable, factory: :'pinboard_service/technical_question'
    end
  end
end
