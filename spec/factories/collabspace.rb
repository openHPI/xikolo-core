# frozen_string_literal: true

FactoryBot.define do
  factory 'collabspace:collabspace', class: Hash do
    id { generate(:uuid) }
    name { 'My Collab Space' }
    is_open { true }
    course_id { '00000001-4800-44449999-000000000001' }
    owner_id { '00000001-3100-4444-9990-000000000088' }

    factory :team do
      kind { 'team' }
      is_open { false }
    end

    initialize_with { attributes.as_json }
  end
end
