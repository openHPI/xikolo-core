# frozen_string_literal: true

FactoryBot.define do
  sequence :quiz_question_id do |i|
    format('00000002-3900-4444-9999-0000000%05d', i)
  end

  factory :quiz_submission_question do
    association :quiz_submission, :submitted
    quiz_question_id
    points { 2.0 }
  end
end
