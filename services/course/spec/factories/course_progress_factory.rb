# frozen_string_literal: true

FactoryBot.define do
  factory :course_progress do
    course
    user_id
  end
end
