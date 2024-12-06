# frozen_string_literal: true

FactoryBot.define do
  factory :submission_file do
    association(:shared_submission, strategy: :create)
    name { 'pa_example.jpg' }
    size { 1024 }
    sequence(:storage_uri) {|i| "s3://xikolo-pa/pas/123/submission/34/a/#{i}.jpg" }
    mime_type { 'image/jpeg' }
    user_id { generate(:user_id) }
  end
end
