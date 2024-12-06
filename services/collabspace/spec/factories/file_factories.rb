# frozen_string_literal: true

FactoryBot.define do
  factory :file, class: 'UploadedFile' do
    association :collab_space

    title { 'My file' }
    description { 'My file description' }
    creator_id { generate(:user_id) }

    transient do
      sequence(:filename) {|n| "uploaded_file_#{n}.pdf" }
      size { 2048 }
    end

    after(:create) do |file, evaluator|
      create(:file_version,
        file_id: file.id,
        original_filename: evaluator.filename,
        blob_uri: "s3://xikolo-collabspace/collabspaces/#{file.collab_space_id}/uploads/#{file.id}/#{evaluator.filename}",
        size: evaluator.size)
    end
  end

  factory :file_version do
    association :file

    sequence(:original_filename) {|n| "uploaded_file_#{n}.pdf" }
    blob_uri { 'abc' }
    size { 2048 }
  end
end
