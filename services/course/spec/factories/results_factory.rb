# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/result', class: 'Result' do
    user_id
    association :item, factory: %i[course_service/item with_max_points]
    dpoints { 1 }
  end
end
