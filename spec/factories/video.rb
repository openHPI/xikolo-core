# frozen_string_literal: true

FactoryBot.define do
  factory :video, class: 'Video::Video' do
    id { generate(:uuid) }
    title { 'Test Video' }
    description { 'Video for testing.' }

    association :pip_stream, factory: :stream

    trait :with_attachments do
      slides_uri { 's3://slides.url' }
      transcript_uri { 's3://transcript.stream.url' }
      reading_material_uri { 's3://reading.stream.url' }

      association :pip_stream, factory: %i[stream with_downloads]
    end

    trait :kaltura do
      association :pip_stream, factory: %i[stream kaltura]
    end

    trait :with_subtitles do
      after(:create) do |video|
        create(:video_subtitle, video:)
        create(:video_subtitle, video:, lang: 'de')
      end
    end
  end

  factory :video_provider, class: 'Video::Provider' do
    sequence(:name) {|n| "provider_#{n}" }

    trait :vimeo do
      provider_type { 'vimeo' }
      credentials do
        {token: 'test-token'}
      end
    end

    trait :kaltura do
      provider_type { 'kaltura' }
      credentials do
        {
          user_id: 'kaltura-user@example.com',
          partner_id: '1234567',
          token_id: 'token-id',
          token: 'secret-token',
        }
      end
    end
  end

  factory :video_subtitle, class: 'Video::Subtitle' do
    id { generate(:uuid) }
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

  factory :subtitle_cue, class: 'Video::SubtitleCue' do
    association :subtitle, strategy: :create, factory: :video_subtitle
    sequence(:identifier) {|n| n }
    sequence(:start) {|n| ((n - 1) * 10).seconds }
    sequence(:stop) {|n| (n * 10).seconds }
    text { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' }
  end

  factory :stream, class: 'Video::Stream' do
    association(:provider, factory: %i[video_provider vimeo])
    sequence(:title) {|n| "Test Title #{n}" }
    sequence(:duration) {|n| 60 * n }
    sequence(:provider_video_id) {|n| (100_000 + n).to_s }
    hd_url { 'http://player.vimeo.com/external/73209171.hd.mp4?s=9d2233269d6cbd749c78c80274f09387' }
    sd_url { 'http://player.vimeo.com/external/73209171.sd.mp4?s=9d2233269d6cbd749c78c80274f09387' }
    poster { 'http://hd.stream.url/poster.jpg' }

    trait :with_downloads do
      hd_download_url { 'http://hd.stream.url/download.mp4' }
      sd_download_url { 'http://sd.stream.url/download.mp4' }
      audio_uri { 's3://audio.url' }
    end

    trait :vimeo do
      provider_video_id { '123456abcdef' }
    end

    trait :kaltura do
      association :provider, factory: %i[video_provider kaltura]
      provider_video_id { '123456abcdef' }
    end
  end

  factory :thumbnail, class: 'Video::Thumbnail' do
    association :video
    sequence(:file_uri) {|n| "s3://xikolo-video/videos/1/#{n}.png" }
    sequence(:start_time) {|n| n * 5 }
  end
end
