# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/item' do
    title { 'Introduction Speech' }
    start_date { 10.days.ago }
    end_date { 17.days.from_now }
    association :content, factory: :video
    published { true }

    association(:section, factory: :'course_service/section', strategy: :create)

    trait :quiz do
      title { 'A Quiz' }
      association :content, factory: :'quiz_service/quiz'
      exercise_type { 'selftest' }
    end

    trait :lti_exercise do
      association :content, factory: :lti_exercise
    end

    trait :homework do
      quiz
      exercise_type { 'main' }
    end

    trait :bonus do
      exercise_type { 'bonus' }
    end

    trait :with_max_points do
      max_dpoints { 10 }
    end

    trait :text do
      title { 'A Text' }
      association :content, factory: :richtext
    end
  end
end
