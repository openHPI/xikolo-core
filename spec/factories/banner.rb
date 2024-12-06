# frozen_string_literal: true

FactoryBot.define do
  factory :banner do
    file_uri { 's3://xikolo-public/banners/banner.jpg' }
    link_url { 'https://www.example.com' }
    link_target { 'self' }
    alt_text { 'A banner' }
    publish_at { Time.zone.now }
  end
end
