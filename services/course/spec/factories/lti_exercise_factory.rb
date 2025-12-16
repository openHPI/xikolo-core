# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/lti_exercise', class: 'CourseService::Duplicated::LtiExercise' do
    association(:lti_provider, factory: :'course_service/lti_provider', strategy: :create)
    title { 'Exercise' }
    weight { nil }
  end
end
