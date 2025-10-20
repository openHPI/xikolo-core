# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/section', class: 'Section' do
    association(:course, factory: :'course_service/course', strategy: :create)
    title { 'Week 1' }
    description { 'This is the first week of your awesome course' }
    start_date { 10.days.from_now.iso8601 }
    end_date  { 17.days.from_now.iso8601 }
    published { true }
    optional_section { false }
    alternative_state { 'none' }

    trait :parent do
      alternative_state { 'parent' }
    end

    trait :child do
      alternative_state { 'child' }
      association :parent, factory: %i[course_service/section parent]
    end
  end
end
