# frozen_string_literal: true

FactoryBot.define do
  factory 'pinboard:root', class: Hash do
    implicit_tags_url { '/implicit_tags{?name,course_id,referenced_resource}' }
    questions_url { '/questions' }
    tags_url { '/tags{?type,course_id,name}' }
    topics_url { '/topics' }
    course_subscriptions_url { '/course_subscriptions{?user_id,course_id}' }
    course_subscription_url { '/course_subscriptions/{id}' }

    initialize_with { attributes.as_json }
  end

  factory 'pinboard:question', class: Hash do
    id { generate(:uuid) }
    user_id { '00000001-3100-4444-9999-000000000001' }
    sequence(:title) {|n| "Test Title #{n}" }
    text { 'SQL seems to be an abbreviation. Does anyone know its meaning?' }
    course_id { '00000001-3300-4444-9999-000000000001' }
    deleted { false }

    initialize_with { attributes.as_json }
  end

  factory 'pinboard:subscription', class: Hash do
    id { generate(:uuid) }
    user_id { '00000001-3100-4444-9999-000000000001' }
    question_id { generate(:uuid) }

    initialize_with { attributes.as_json }
  end
end
