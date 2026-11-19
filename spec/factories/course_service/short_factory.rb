# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/short' do
    title_translations { {'de' => 'Short DE', 'en' => 'Short EN'} }
    description_translations { {'de' => 'Short description DE', 'en' => 'Short description EN'} }
    course_id { create(:'course_service/course').id }
    status { 'preparation' }

    trait :with_video do
      after(:create) do |short|
        short.video.attach(
          io: StringIO.new('video data'),
          filename: 'video.mp4',
          content_type: 'video/mp4'
        )
      end
    end
  end
end
