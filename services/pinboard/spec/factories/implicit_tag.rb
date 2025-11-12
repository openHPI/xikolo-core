# frozen_string_literal: true

FactoryBot.define do
  factory :'pinboard_service/implicit_tag', class: 'PinboardService::ImplicitTag' do
    course_id { '00000001-3300-4444-9999-000000000001' }
    referenced_resource { nil }
    name { '00000001-3500-4444-9999-000000000000' }
    initialize_with do
      PinboardService::ImplicitTag.where(name:).first_or_create
    end

    factory :'pinboard_service/section_tag', class: 'PinboardService::ImplicitTag' do
      referenced_resource { 'Xikolo::Course::Section' }
      name { '00000001-3500-4444-9999-000000000001' }
    end

    factory :'pinboard_service/video_item_tag', class: 'PinboardService::ImplicitTag' do
      referenced_resource { 'Xikolo::Course::Item' }
      name { generate(:item_id) }
    end

    factory :'pinboard_service/video_item_tag_2', class: 'PinboardService::ImplicitTag' do
      referenced_resource { 'Xikolo::Course::Item' }
      course_id { '00000001-3300-4444-9999-000000000002' }
      name { '00000002-3500-4444-9999-000000000002' }
    end

    factory :'pinboard_service/new_implicit_tag', class: 'PinboardService::ImplicitTag' do
      course_id { '00000001-3300-4444-9999-000000000002' }
      referenced_resource { 'Xikolo::Course::Item' }
      name { '00000002-3500-4444-9999-000000000003' }
    end

    factory :'pinboard_service/technical_issues_tag', class: 'PinboardService::ImplicitTag' do
      name { 'Technical Issues' }
      referenced_resource { nil }
    end
  end
end
