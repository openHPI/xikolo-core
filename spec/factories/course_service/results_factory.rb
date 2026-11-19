# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/result' do
    association(:user, factory: :'account_service/user', strategy: :create)
    association :item, factory: %i[course_service/item with_max_points]
    dpoints { 1 }
  end
end
