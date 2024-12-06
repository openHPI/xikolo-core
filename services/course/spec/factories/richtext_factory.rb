# frozen_string_literal: true

FactoryBot.define do
  factory :richtext do
    id { generate(:richtext_id) }
    text { 'Some Text' }
    course
  end
end
