# frozen_string_literal: true

FactoryBot.define do
  factory :'pinboard_service/explicit_tag', class: 'PinboardService::ExplicitTag' do
    course_id { '00000001-3300-4444-9999-000000000001' }
    name { 'default' }
    initialize_with do
      PinboardService::ExplicitTag.where(name:).first_or_create
    end

    factory :'pinboard_service/sql_tag', class: 'PinboardService::ExplicitTag' do
      course_id { '00000001-3300-4444-9999-000000000001' }
      name { 'SQL' }
      type { 'PinboardService::ExplicitTag' }
    end

    factory :'pinboard_service/definition_tag', class: 'PinboardService::ExplicitTag' do
      course_id { '00000001-3300-4444-9999-000000000001' }
      name { 'Definition' }
      type { 'PinboardService::ExplicitTag' }
    end

    factory :'pinboard_service/offtopic_tag', class: 'PinboardService::ExplicitTag' do
      course_id { '00000001-3300-4444-9999-000000000002' }
      name { 'Off-Topic' }
      type { 'PinboardService::ExplicitTag' }
    end

    factory :'pinboard_service/new_explicit_tag', class: 'PinboardService::ExplicitTag' do
      course_id { '00000001-3300-4444-9999-000000000002' }
      name { 'New' }
      type { 'PinboardService::ExplicitTag' }
    end

    factory :'pinboard_service/wrong_explicit_tag', class: 'PinboardService::ExplicitTag' do
      course_id { '00000001-3300-4444-9999-000000000002' }
      name { '00000002-3500-4444-9999-900000000003' }
      type { 'PinboardService::ExplicitTag' }
    end
  end
end
