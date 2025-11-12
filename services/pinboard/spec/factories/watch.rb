# frozen_string_literal: true

FactoryBot.define do
  factory :'pinboard_service/watch', class: 'PinboardService::Watch' do
    user_id { '00000001-3100-4444-9999-000000000001' }
    association :question, factory: :'pinboard_service/question', strategy: :create
  end
end
