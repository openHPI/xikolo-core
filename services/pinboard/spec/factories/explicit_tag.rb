# frozen_string_literal: true

FactoryBot.define do
  factory :explicit_tag do
    course_id { '00000001-3300-4444-9999-000000000001' }
    name { 'default' }
    initialize_with do
      ExplicitTag.where(name:).first_or_create
    end

    factory :sql_tag do
      course_id { '00000001-3300-4444-9999-000000000001' }
      name { 'SQL' }
      type { 'ExplicitTag' }
    end

    factory :definition_tag do
      course_id { '00000001-3300-4444-9999-000000000001' }
      name { 'Definition' }
      type { 'ExplicitTag' }
    end

    factory :offtopic_tag do
      course_id { '00000001-3300-4444-9999-000000000002' }
      name { 'Off-Topic' }
      type { 'ExplicitTag' }
    end

    factory :new_explicit_tag do
      course_id { '00000001-3300-4444-9999-000000000002' }
      name { 'New' }
      type { 'ExplicitTag' }
    end

    factory :wrong_explicit_tag do
      course_id { '00000001-3300-4444-9999-000000000002' }
      name { '00000002-3500-4444-9999-900000000003' }
      type { 'ExplicitTag' }
    end
  end
end
