# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/enrollment' do
    association(:course, factory: :'course_service/course', strategy: :create)
    association(:user, factory: :'account_service/user', strategy: :create)
    deleted { false }
    forced_submission_date { nil }
    quantile { nil }
    quantiled_user_dpoints { nil }
    completed { false }

    trait :with_evaluation do
      after(:create) do |enrollment|
        create(:'course_service/course_progress',
          user_id: enrollment.user_id,
          course_id: enrollment.course_id,
          visits: 10,
          max_visits: 20,
          visits_percentage_fpoints: 5000, # 50.00% * 100
          main_dpoints: 70,
          bonus_dpoints: 10,
          max_dpoints: 100,
          points_percentage_fpoints: 8000) # 80.00% * 100
      end
    end

    trait :with_low_evaluation do
      after(:create) do |enrollment|
        create(:'course_service/course_progress',
          user_id: enrollment.user_id,
          course_id: enrollment.course_id,
          visits: 5,
          max_visits: 20,
          visits_percentage_fpoints: 2500, # 25.00% * 100
          main_dpoints: 40,
          bonus_dpoints: 15,
          max_dpoints: 100,
          points_percentage_fpoints: 4500) # 45.00% * 100
      end
    end

    trait :reactivated do
      forced_submission_date { 6.weeks.from_now }
    end

    trait :was_reactivated do
      forced_submission_date { 2.years.ago }
    end

    factory :'course_service/deleted_enrollment' do
      deleted { true }
    end
  end
end
