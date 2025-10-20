# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/teacher', class: 'Teacher' do
    sequence(:name) {|i| "Teacher #{i}" }
    description { {de: 'Deutsch', en: 'English'} }
    user_id { nil }

    trait :connected_to_user do
      user_id
    end
  end
end
