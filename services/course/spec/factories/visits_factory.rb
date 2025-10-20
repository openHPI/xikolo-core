# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/visit', class: 'Visit' do
    user_id
    association :item, factory: :'course_service/item'
    updated_at { Time.current }
  end
end
