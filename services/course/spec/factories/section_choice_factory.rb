# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/section_choice' do
    association :section, factory: %i[course_service/section parent]
    user_id { SecureRandom.uuid }
  end
end
