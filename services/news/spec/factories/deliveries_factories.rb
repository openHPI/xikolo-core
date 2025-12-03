# frozen_string_literal: true

FactoryBot.define do
  factory :'news_service/delivery' do
    association :message, factory: :'news_service/message'
    user_id { generate(:uuid) }
  end
end
