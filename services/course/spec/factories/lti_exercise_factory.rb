# frozen_string_literal: true

FactoryBot.define do
  factory :lti_exercise, class: 'Duplicated::LtiExercise' do
    association(:lti_provider, strategy: :create)
    title { 'Exercise' }
    weight { nil }
  end
end
