# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/course_provider' do
    sequence(:name) {|n| "provider-#{n}" }
    sequence(:provider_type) {|n| "Provider#{n}" }
    config { {key: 'value'} }
    enabled { true }
  end
end
