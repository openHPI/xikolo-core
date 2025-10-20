# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/course_progress', class: 'CourseProgress' do
    association :course, factory: :'course_service/course'
    user_id
  end
end
