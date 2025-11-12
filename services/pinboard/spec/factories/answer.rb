# frozen_string_literal: true

FactoryBot.define do
  factory :'pinboard_service/answer', class: 'PinboardService::Answer' do
    text { 'SQL stands for Structured Query Language.' }
    association :question, factory: :'pinboard_service/question'
    user_id { '00000001-3100-4444-9999-000000000002' }

    factory :'pinboard_service/technical_answer' do
      association :question, factory: :'pinboard_service/technical_question'
    end

    factory :'pinboard_service/answer_with_comment' do
      after(:create) do |answer|
        create(:'pinboard_service/comment', commentable: answer, commentable_type: 'PinboardService::Answer')
      end
    end
  end
end
