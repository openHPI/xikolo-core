# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/offer', class: 'Duplicated::Offer' do
    association(:course, factory: :'course_service/course')
  end
end
