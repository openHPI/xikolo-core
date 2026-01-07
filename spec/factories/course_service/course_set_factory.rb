# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/course_set' do
    sequence :name do |n|
      "foo#{n}"
    end
  end
end
