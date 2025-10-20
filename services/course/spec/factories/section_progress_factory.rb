# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/section_progress', class: 'SectionProgress' do
    association :section, factory: :'course_service/section'
    user_id
  end
end
