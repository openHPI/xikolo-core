# frozen_string_literal: true

require 'securerandom'

FactoryBot.define do
  factory :'timeeffort_service/item' do
    id { '00000001-3300-4444-9999-000000000001' }
    content_id { '00000001-3800-4444-9999-000000000001' }
    content_type { 'quiz' }
    section_id { '00000002-3300-4444-9999-000000000001' }
    course_id { '00000003-3300-4444-9999-000000000001' }
    time_effort { 30 }
    calculated_time_effort { 30 }
    time_effort_overwritten { false }

    trait :time_effort_overwritten do
      time_effort_overwritten { true }
    end
  end

  factory :'timeeffort_service/time_effort_job' do
    association :item, factory: :'timeeffort_service/item'
    job_id { nil }
    status { 'waiting' }

    trait :started do
      status { 'started' }
      job_id { SecureRandom.uuid }
    end

    trait :cancelled do
      status { 'cancelled' }
    end
  end

  factory :'timeeffort_service/duplicated/video' do
    pip_stream_id { SecureRandom.uuid }

    trait :pip
  end

  factory :'timeeffort_service/duplicated/stream' do
    provider_video_id { '123456abcdef' }
    duration { 1800 }
  end
end
