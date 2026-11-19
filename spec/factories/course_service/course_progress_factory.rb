# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/course_progress' do
    association :course, factory: :'course_service/course'
    user_id
    course_id { course.id }
    visits { 10 }
    main_dpoints { 100 }
    main_exercises { 1 }
    bonus_dpoints { 5 }
    bonus_exercises { 1 }
    selftest_dpoints { 10 }
    selftest_exercises { 1 }
    created_at { Time.current }
    updated_at { Time.current }
    max_dpoints { 100 }
    max_visits { 10 }
    points_percentage_fpoints { 10_000 }
    visits_percentage_fpoints { 10_000 }
  end
end
