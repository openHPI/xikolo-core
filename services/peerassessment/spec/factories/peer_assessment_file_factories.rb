# frozen_string_literal: true

FactoryBot.define do
  factory :peer_assessment_file do
    association(:peer_assessment, strategy: :create)
    name { 'pa_example.jpg' }
    size { 1024 }
    sequence(:storage_uri) {|i| "s3://xikolo-pa/pas/123/a/#{i}.jpg" }
    mime_type { 'image/jpeg' }
    user_id { generate(:user_id) }
  end
end
