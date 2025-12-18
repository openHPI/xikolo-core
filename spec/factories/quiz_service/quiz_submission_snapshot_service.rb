# frozen_string_literal: true

FactoryBot.define do
  factory :'quiz_service/quiz_submission_snapshot' do
    association :quiz_submission, factory: :'quiz_service/quiz_submission'
  end
end
