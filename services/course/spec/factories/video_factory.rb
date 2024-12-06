# frozen_string_literal: true

FactoryBot.define do
  factory :video, class: 'Duplicated::Video' do
    id { SecureRandom.uuid }
    pip_stream_id { SecureRandom.uuid }
    trait :with_slides do
      slides_uri { "s3://xikolo-video/videos/#{id}/encodedUUUID/slides.pdf" }
    end

    trait :with_transcript do
      transcript_uri { "s3://xikolo-video/videos/#{id}/encodedUUUID/transcript.pdf" }
    end

    trait :with_reading_material do
      reading_material_uri { "s3://xikolo-video/videos/#{id}/encodedUUUID/reading_material.pdf" }
    end
  end

  factory :subtitle, class: 'Duplicated::Subtitle' do
    association :video
    lang { 'en' }
    automatic { false }

    trait :with_cues do
      transient do
        cues { 1 }
      end

      after(:create) do |subtitle, evaluator|
        create_list(:subtitle_cue, evaluator.cues, subtitle:)
      end
    end
  end

  factory :subtitle_cue, class: 'Duplicated::SubtitleCue' do
    association :subtitle, strategy: :create
    sequence(:identifier) {|n| n }
    sequence(:start) {|n| ((n - 1) * 10).seconds }
    sequence(:stop) {|n| (n * 10).seconds }
    text { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' }
  end
end
