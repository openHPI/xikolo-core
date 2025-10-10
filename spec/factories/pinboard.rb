# frozen_string_literal: true

FactoryBot.define do
  factory 'pinboard:question', class: Hash do
    id { generate(:uuid) }
    user_id { '00000001-3100-4444-9999-000000000001' }
    sequence(:title) {|n| "Test Title #{n}" }
    text { 'SQL seems to be an abbreviation. Does anyone know its meaning?' }
    course_id { '00000001-3300-4444-9999-000000000001' }
    deleted { false }

    initialize_with { attributes.as_json }
  end

  factory 'pinboard:subscription', class: Hash do
    id { generate(:uuid) }
    user_id { '00000001-3100-4444-9999-000000000001' }
    question_id { generate(:uuid) }

    initialize_with { attributes.as_json }
  end
end
