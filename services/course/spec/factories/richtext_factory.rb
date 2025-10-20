# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/richtext', class: 'Richtext' do
    id { generate(:richtext_id) }
    text { 'Some Text' }
    association :course, factory: :'course_service/course'
  end
end
