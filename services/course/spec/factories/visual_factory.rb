# frozen_string_literal: true

FactoryBot.define do
  factory :visual, class: 'Duplicated::Visual' do
    association(:course)

    image_uri { "s3://xikolo-public/courses/#{UUID4(course.id).to_s(format: :base62)}/encodedUUUID/course_visual.png" }

    trait :with_video do
      association(:video)
    end
  end
end
