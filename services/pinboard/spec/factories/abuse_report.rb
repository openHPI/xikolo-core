# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_report do
    user_id { SecureRandom.uuid }
    reportable_type { 'Question' }
    association :reportable, factory: :question, strategy: :create
    course_id { SecureRandom.uuid }
  end
end
