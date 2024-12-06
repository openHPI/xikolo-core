# frozen_string_literal: true

FactoryBot.define do
  factory :collab_space do
    name { 'My Collab Space' }
    is_open { true }
    sequence :course_id, '00000001-4800-4444-9999-000000000001'
    owner_id { '00000001-3100-4444-9990-000000000088' }

    factory :team do
      kind { 'team' }
      is_open { false }
    end

    trait :same_course do
      course_id { '00000001-4700-4444-9999-000000000001' }
    end
  end
end
