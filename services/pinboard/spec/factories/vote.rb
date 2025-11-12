# frozen_string_literal: true

FactoryBot.define do
  factory :'pinboard_service/vote', class: 'PinboardService::Vote' do
    value { 1 }
    association :votable, factory: :'pinboard_service/question'
    votable_type { 'PinboardService::Question' }
    sequence(:user_id, 1000) {|n| "00000001-3100-4444-9999-00000000#{n}" }
  end

  trait :for_answer do
    association :votable, factory: :'pinboard_service/answer'
    votable_type { 'PinboardService::Answer' }
  end
end
