# frozen_string_literal: true

FactoryBot.define do
  factory :course do
    sequence :title do |n|
      "In-Memory Data Management-Entwicklung - Iteration #{n}"
    end
    abstract { 'This is a nice course about cool stuff' }
    sequence :course_code do |n|
      "inmemorydatabases#{n}"
    end
    status { 'preparation' }
    context_id
    description { 'Some course ...' }
    start_date { Time.zone.now }
    end_date { 6.weeks.from_now }
    lang { 'en' }
    middle_of_course { nil }
    classifiers { {create(:cluster).id => %w[pro-track databases]} }
    hidden { false }
    auto_archive { true }
    invite_only { false }
    enrollment_delta { 0 }
    channel_id { nil }
    has_collab_space { true }
    on_demand { true }

    trait :with_content_tree do
      after(:create, &:create_node!)
    end

    trait :with_channel do
      after(:create) do |course|
        course.channel = FactoryBot.create(:channel)
        course.save
      end
    end

    trait :with_teachers do
      teacher_ids { %w[6551282f-b22f-43dd-855c-2860f560f54e 0e3c0346-de8c-4dc0-9056-8da93cc2af69] }
    end

    trait :with_sections do
      after(:create) do |course|
        course.sections << FactoryBot.create(:section, course:)
        course.sections << FactoryBot.create(:section, course:, title: 'Week 2', start_date: 17.days.from_now, end_date: 24.days.from_now)
        course.sections << FactoryBot.create(:section, course:, title: 'Final Exam', start_date: 24.days.from_now, end_date: 31.days.from_now)
      end
    end

    trait :full_blown do
      teacher_ids { %w[6551282f-b22f-43dd-855c-2860f560f54e] }

      after(:create) do |course|
        section_parent = FactoryBot.create(:section, course:, alternative_state: 'parent')
        course.sections << section_parent

        section1 = FactoryBot.create(:section, course:, alternative_state: 'child', parent_id: section_parent.id)
        richtext = Richtext.create course_id: course.id, text: 'Useful information!'
        video = FactoryBot.create(:video)
        section1.items << FactoryBot.create(:item, section: section1, title: 'Wiki', content_type: 'rich_text', content_id: richtext.id)
        section1.items << FactoryBot.create(:item, section: section1, title: 'Video', content_type: 'video', content_id: video.id)

        course.sections << section1

        section2 = FactoryBot.create(:section, course:, alternative_state: 'child', parent_id: section_parent.id)
        section2.items << FactoryBot.create(:item, section: section2, title: 'Quiz', content_type: 'quiz', exercise_type: 'selftest', content_id: '00000000-3333-4444-9999-000000000001')
        course.sections << section2
      end
    end

    trait :archived do
      status { 'archive' }
      start_date { 4.months.ago }
      end_date { 3.months.ago }
    end

    trait :active do
      status { 'active' }
      start_date { 2.weeks.ago }
      end_date { 4.weeks.from_now }
    end

    trait :upcoming do
      status { 'active' }
      start_date { 2.weeks.from_now }
      end_date { 8.weeks.from_now }
    end

    trait :self_paced do
      status { 'active' }
      start_date { nil }
      end_date { nil }
    end

    trait :with_custom_middle_date do
      middle_of_course { Time.new(2012, 12, 1, 0, 0, 0).utc }
    end

    trait :external do
      external_course_url { 'https://mooc.house/course/external' }
    end

    trait :invite_only do
      invite_only { true }
    end
  end
end
