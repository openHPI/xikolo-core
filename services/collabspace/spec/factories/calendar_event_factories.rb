# frozen_string_literal: true

FactoryBot.define do
  factory :calendar_event do
    association :collab_space
    user_id
    sequence(:title) {|n| "Meeting #{1 + n}" }
    description { 'This is a test entry' }
    start_time { 10.days.from_now }
    end_time { 17.days.from_now }
    category { 'other' }
    all_day { false }
  end
end
