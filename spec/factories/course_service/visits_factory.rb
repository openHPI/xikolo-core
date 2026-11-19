# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/visit' do
    association(:user, factory: :'account_service/user', strategy: :create)
    association :item, factory: :'course_service/item'
    updated_at { Time.current }
  end
end
