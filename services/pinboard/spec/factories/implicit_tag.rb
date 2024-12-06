# frozen_string_literal: true

FactoryBot.define do
  factory :implicit_tag do
    course_id { '00000001-3300-4444-9999-000000000001' }
    referenced_resource { nil }
    name { '00000001-3500-4444-9999-000000000000' }
    initialize_with do
      ImplicitTag.where(name:).first_or_create
    end

    factory :section_tag do
      referenced_resource { 'Xikolo::Course::Section' }
      name { '00000001-3500-4444-9999-000000000001' }
    end

    factory :video_item_tag do
      referenced_resource { 'Xikolo::Course::Item' }
      name { generate(:item_id) }
    end

    factory :video_item_tag_2 do
      referenced_resource { 'Xikolo::Course::Item' }
      course_id { '00000001-3300-4444-9999-000000000002' }
      name { '00000002-3500-4444-9999-000000000002' }
    end

    factory :new_implicit_tag do
      course_id { '00000001-3300-4444-9999-000000000002' }
      referenced_resource { 'Xikolo::Course::Item' }
      name { '00000002-3500-4444-9999-000000000003' }
    end

    factory :technical_issues_tag do
      name { 'Technical Issues' }
      referenced_resource { nil }
    end
  end
end
