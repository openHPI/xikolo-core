# frozen_string_literal: true

FactoryBot.define do
  factory :lti_provider, class: 'Duplicated::LtiProvider' do
    course_id
    consumer_key { 'key' }
    domain { 'https://example.com/lti' }
    name { 'Provider' }
    presentation_mode { 'pop-up' }
    shared_secret { 'secret' }
    privacy { 'anonymized' }

    trait :global do
      course_id { nil }
    end
  end
end
