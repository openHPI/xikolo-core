# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/course' do
    transient do
      skip_account_groups { false }
    end
    sequence :title do |n|
      "In-Memory Data Management-Entwicklung - Iteration #{n}"
    end
    abstract { 'This is a nice course about cool stuff' }
    sequence :course_code do |n|
      "inmemorydatabases#{n}"
    end
    published { true }
    description { 'Some course ...' }
    start_date { 2.weeks.ago }
    end_date { 4.weeks.from_now }
    lang { 'en' }
    middle_of_course { nil }
    placement { ['Open4All'] }
    invite_only { false }
    enrollment_delta { 0 }
    on_demand { true }

    trait :with_content_tree do
      after(:create, &:create_node!)
    end

    trait :with_channel do
      after(:create) do |course|
        course.channels << FactoryBot.create(:'course_service/channel')
        course.save
      end
    end

    trait :with_teachers do
      teacher_ids { %w[6551282f-b22f-43dd-855c-2860f560f54e 0e3c0346-de8c-4dc0-9056-8da93cc2af69] }
    end

    trait :with_sections do
      after(:create) do |course|
        course.sections << FactoryBot.create(:'course_service/section', course:)
        course.sections << FactoryBot.create(:'course_service/section', course:, title: 'Week 2', start_date: 17.days.from_now, end_date: 24.days.from_now)
        course.sections << FactoryBot.create(:'course_service/section', course:, title: 'Final Exam', start_date: 24.days.from_now, end_date: 31.days.from_now)
      end
    end

    trait :full_blown do
      teacher_ids { %w[6551282f-b22f-43dd-855c-2860f560f54e] }

      after(:create) do |course|
        section_parent = FactoryBot.create(:'course_service/section', course:, alternative_state: 'parent')
        course.sections << section_parent

        section1 = FactoryBot.create(:'course_service/section', course:, alternative_state: 'child', parent_id: section_parent.id)
        richtext = CourseService::Richtext.create! course_id: course.id, text: 'Useful information!'
        video = FactoryBot.create(:video)
        section1.items << FactoryBot.create(:'course_service/item', section: section1, title: 'Wiki', content: richtext)
        section1.items << FactoryBot.create(:'course_service/item', section: section1, title: 'Video', content: video)

        course.sections << section1

        section2 = FactoryBot.create(:'course_service/section', course:, alternative_state: 'child', parent_id: section_parent.id)
        section2.items << FactoryBot.create(:'course_service/item', :quiz, section: section2, title: 'Quiz')
        course.sections << section2
      end
    end

    trait :active do
      # Rule 2: no start + future end → active
      start_date { 1.day.ago }
      end_date { 4.weeks.from_now }
    end

    trait :upcoming do
      # Rule 5: future start + future end → upcoming
      start_date { 1.week.from_now }
      end_date { 8.weeks.from_now }
    end

    trait :self_paced do
      # Rule 9: past start + past end → self-paced
      start_date { 2.weeks.ago }
      end_date { 1.week.ago }
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

    trait :with_classifiers do
      after(:create) do |course|
        cluster = create(:'course_service/cluster', id: 'category')
        course.classifiers << create(:'course_service/classifier', cluster:, title: 'category', position: 1, translations: {en: 'pro-track'})
        course.classifiers << create(:'course_service/classifier', cluster:, title: 'topic', position: 2, translations: {en: 'databases'})
      end
    end

    # Grant default course permissions. This creates the same resources as
    # CourseService::Course::Create without internal API calls.
    after(:create) do |course, evaluator|
      next if evaluator.skip_account_groups

      context = create(:'account_service/context', reference_uri: "urn:x-xikolo:course:course:#{course.course_code}")
      course.update_column(:context_id, context.id) # rubocop:disable Rails/SkipsModelValidations

      special_groups = []
      Xikolo.config.course_groups.each do |name, data|
        group = create('account_service/group', name: "course.#{course.course_code}.#{name}", description: data.fetch('description') % course.course_code)

        data.fetch('grants').each do |grant|
          grant_context = grant.fetch('context') == 'root' ? AccountService::Context.root : context
          role = AccountService::Role.resolve(grant.fetch('role'))
          create('account_service/grant', context: grant_context, principal: group, role:)
        end

        special_groups << name unless name == 'students'
      end
      course.update_column(:special_groups, special_groups) # rubocop:disable Rails/SkipsModelValidations

      role = AccountService::Role.resolve('course.visitor')
      create('account_service/grant', context: AccountService::Context.root, principal: AccountService::Group.all_users, role:)
    end
  end
end
