# frozen_string_literal: true

FactoryBot.define do
  factory :rubric_option do
    description { 'Lorem Ipsum Description' }
    sequence :points
    association :rubric, strategy: :create
  end
end
