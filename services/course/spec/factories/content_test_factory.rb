# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/content_test', class: 'ContentTest' do
    identifier { 'human-readable-identifier-for-ui' }
    groups { %w[plain game] }

    association(:course, factory: :'course_service/course')
  end
end
