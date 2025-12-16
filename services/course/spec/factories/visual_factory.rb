# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/visual', class: 'CourseService::Duplicated::Visual' do
    association(:course, factory: :'course_service/course')

    image_uri { "s3://xikolo-public/courses/#{UUID4(course.id).to_s(format: :base62)}/encodedUUUID/course_visual.png" }

    trait :with_video do
      association(:video, factory: :'course_service/video')
    end
  end
end
