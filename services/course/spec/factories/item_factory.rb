# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/item', class: 'Item' do
    title { 'Introduction Speech' }
    start_date { 10.days.ago }
    end_date { 17.days.from_now }
    content_type { 'video' }
    content_id { 'b2157ab3-454b-4777-bb31-976b99cb016f' }
    time_effort { 120 }

    association(:section, factory: :'course_service/section', strategy: :create)

    trait :quiz do
      title { 'A Quiz' }
      content_type { 'quiz' }
      exercise_type { 'selftest' }
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
      content_type { 'richtext' }
    end

    trait :proctored do
      proctored { true }
      submission_deadline { 5.days.from_now }
    end
  end
end
