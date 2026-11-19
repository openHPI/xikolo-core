# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/next_date', class: 'CourseService::NextDate' do
    association :course, factory: :'course_service/course'
    transient do
      user_id { nil }
    end

    slot_id { SecureRandom.uuid }
    date { 1.day.from_now }
    resource_id { SecureRandom.uuid }
    resource_type { 'CourseService::Item' }
    title { 'Test Date' }
    type { 'upcoming' }
  end
end
