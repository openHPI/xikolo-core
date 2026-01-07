# frozen_string_literal: true

FactoryBot.define do
  factory 'course:course', class: Hash do
    id { generate(:course_id) }
    sequence :title do |n|
      "In-Memory Data Management-Entwicklung - Iteration #{n}"
    end
    course_code { 'my-course' }

    status { 'active' }
    teacher_ids { [] }
    lang { 'en' }

    classifiers { {} }

    show_on_stage { false }
    stage_visual_uri { '' }
    stage_statement { '' }
    roa_enabled { true }
    cop_enabled { true }
    roa_threshold_percentage { 50 }
    cop_threshold_percentage { 50 }
    achievements_url { "/course_service/courses/#{id}/achievements{?user_id}" }

    trait :german do
      lang { 'de' }
    end

    trait :proctored do
      proctored { true }
    end

    trait :current do
      start_date { 2.weeks.ago.iso8601(3) }
      end_date { 2.weeks.from_now.iso8601(3) }
    end

    trait :upcoming do
      start_date { 6.weeks.from_now.iso8601(3) }
      end_date { 10.weeks.from_now.iso8601(3) }
    end

    trait :self_paced do
      start_date { nil }
      end_date { nil }
    end

    initialize_with { attributes.as_json }
  end

  factory 'course:enrollment', class: Hash do
    id { generate(:uuid) }
    user_id
    course_id

    factory 'course:enrollment:evaluated' do
      completed { true }
    end

    trait :proctored do
      proctored { true }
    end

    trait :deleted do
      deleted { true }
    end

    trait :with_learning_evaluation do
      certificates do
        {
          record_of_achievement: true,
          confirmation_of_participation: true,
          certificate: false,
        }
      end
    end

    initialize_with { attributes.as_json }
  end

  factory 'course:channel', class: Hash do
    id { generate(:uuid) }
    code { 'my-code' }
    description { {'en' => 'English!', 'de' => 'Deutsch!'} }
    video_stream_id { nil }
    stage_statement { '' }

    public { true }

    initialize_with { attributes.as_json }
  end

  xikolo_uuid_sequence(:teacher_id, service: 3300, resource: 3)

  factory 'course:teacher', class: Hash do
    id { generate(:teacher_id) }
    sequence(:name) {|i| "Hans Otto #{i}" }
    description { {'en' => 'Teacher in English!', 'de' => 'Lehrer in Deutsch!'} }

    initialize_with { attributes.as_json }
  end

  factory 'course:section', class: Hash do
    id { generate(:section_id) }
    course_id
    sequence(:title) {|i| "Section #{i}" }
    published { true }
    effective_start_date { 4.days.ago.iso8601(3) }

    initialize_with { attributes.as_json }
  end

  factory 'course:item', class: Hash do
    id { generate(:item_id) }
    section_id
    course_id
    sequence(:title) {|i| "Item #{i}" }
    published { true }
    course_archived { false }
    effective_start_date { 2.days.ago.iso8601(3) }

    trait :exam do
      exercise_type { 'main' }
      submission_deadline { 2.days.from_now.iso8601(3) }
    end

    trait :quiz do
      content_type { 'quiz' }
      content_id { generate(:quiz_id) }
    end

    trait :proctored do
      proctored { true }
    end

    trait :video do
      content_type { 'video' }
      content_id { generate(:uuid) }
    end

    trait :lti_exercise do
      content_type { 'lti_exercise' }
      content_id { generate(:uuid) }
    end

    initialize_with { attributes.as_json }
  end

  factory 'course:achievement', class: Hash do
    type { 'certificate_type' }
    name { 'Certificate name' }
    description { 'Certificate description' }
    achieved { true }
    achievable { true }
    requirements { 'Certificate requirements' }
    download { nil }

    trait :cop do
      type { 'confirmation_of_participation' }
      name { 'Confirmation of Participation' }
      visits { {'achieved' => 2.0, 'total' => 2.0, 'percentage' => 100} }
    end

    trait :roa do
      type { 'record_of_achievement' }
      name { 'Record of Achievement' }
      points { {'achieved' => 2.0, 'total' => 2.0, 'percentage' => 100} }
    end

    initialize_with { attributes.as_json }
  end

  factory 'course:classifier', class: Hash do
    sequence(:title) {|n| "Database Track ##{n}" }
    descriptions { {'en' => 'In this category you will find courses about Databases and related technologies'} }

    initialize_with { attributes.as_json }
  end

  factory 'course:progresses', class: 'Array' do
    association(:section_progress, factory: 'course:section_progress')
    association(:course_progress, factory: 'course:progress')

    initialize_with { attributes.values }
  end

  factory 'course:progress', class: Hash do
    bonus_exercises do
      {
        'graded_exercises' => 3, 'graded_points' => 23.0, 'max_points' => 26.0, 'submitted_exercises' => 3,
      'submitted_points' => 23.0, 'total_exercises' => 3
      }
    end
    main_exercises do
      {
        'graded_exercises' => 1, 'graded_points' => 12.0, 'max_points' => 38.0, 'submitted_exercises' => 1,
        'submitted_points' => 12.0, 'total_exercises' => 6
      }
    end
    selftest_exercises do
      {
        'graded_exercises' => 1, 'graded_points' => 0.0, 'max_points' => 4.0, 'submitted_exercises' => 1,
        'submitted_points' => 0.0, 'total_exercises' => 2
      }
    end
    visits do
      {
        'percentage' => 93, 'total' => 16, 'user' => 15
      }
    end
    initialize_with { attributes.as_json }
  end

  factory 'course:section_progress', class: Hash do
    sequence(:title) {|n| "Section #{n}" }
    bonus_exercises do
      {
        'max_points' => 8.0, 'graded_points' => 5.0, 'submitted_points' => 5.0, 'total_exercises' => 1, 'graded_exercises' => 1, 'submitted_exercises' => 1
      }
    end
    main_exercises do
      {
        'max_points' => 26.0, 'graded_points' => 0.0, 'submitted_points' => 22.0, 'total_exercises' => 4, 'graded_exercises' => 0, 'submitted_exercises' => 3
      }
    end
    selftest_exercises do
      {
        'max_points' => 4.0, 'graded_points' => 0.0, 'submitted_points' => 4.0, 'total_exercises' => 2, 'graded_exercises' => 1, 'submitted_exercises' => 2
      }
    end
    visits do
      {
        'percentage' => 93, 'total' => 16, 'user' => 15
      }
    end
    items do
      [
        {
          'id' => '19b3bc6b-f2f7-4a52-aab5-e0ce75d78b3f',
          'title' => 'Week 1: Quiz 1',
          'content_type' => 'quiz',
          'exercise_type' => 'main',
          'user_state' => 'submitted',
          'optional' => false,
          'icon_type' => nil,
          'max_points' => 10.0,
          'user_points' => nil,
          'time_effort' => nil,
          'open_mode' => false,
        },
        {
          'id' => '5c5ace91-1b24-46ea-a8a4-9e1340270437',
          'title' => 'Week 1: Quiz 2',
          'content_type' => 'quiz',
          'exercise_type' => 'main',
          'user_state' => 'visited',
          'optional' => false,
          'icon_type' => nil,
          'max_points' => 7.0,
          'user_points' => nil,
          'time_effort' => nil,
          'open_mode' => false,
        },
        {
          'id' => '1916244a-2579-4246-8085-79bede781ec4',
          'title' => 'Week 1: Quiz 2.2 (Branch A)',
          'content_type' => 'quiz',
          'exercise_type' => 'main',
          'user_state' => 'visited',
          'optional' => false,
          'icon_type' => nil,
          'max_points' => 9.0,
          'user_points' => nil,
          'time_effort' => nil,
          'open_mode' => false,
        },
      ]
    end
    initialize_with { attributes.as_json }
  end

  factory 'course:activity:statistics', class: Hash do
    activity do
      {'name' => 'active_user_count',
      'available' => true,
      'datasources' => ['exp_events_elastic'],
      'description' => 'The number of distinct active users. The default time range is 30 minutes.',
      'required_params' => [],
      'optional_params' => %w[start_date end_date course_id resource_id]}
    end
    initialize_with { attributes.as_json }
  end

  factory 'course:cerfiticate:statistics', class: Hash do
    certificates do
      {'name' => 'certificates',
      'available' => true,
      'datasources' => ['exp_events_elastic'],
      'description' => 'Returns the number of gained certificates.',
      'required_params' => [],
      'optional_params' => %w[course_id start_date end_date]}
    end

    certificate_amounts do
      {'record_of_achievement' => 0, 'confirmation_of_participation' => 0, 'qualified_certificate' => 0}
    end
    initialize_with { attributes.as_json }
  end

  factory 'course:enrollment:statistics', class: Hash do
    account do
      {
        'confirmed_users' => 217,
      'confirmed_users_last_day' => 0,
      'confirmed_users_last_7days' => 0,
      'unconfirmed_users' => 3,
      'unconfirmed_users_last_day' => 0,
      'users_deleted' => 0,
      'users_with_suspended_email' => 0,
      }
    end

    course do
      {
        'platform_current_enrollments' => 217,
      'platform_last_day_enrollments' => 0,
      'platform_enrollments' => 217,
      'platform_last_7days_enrollments' => 0,
      'platform_last_day_unique_enrollments' => 0,
      'platform_enrollment_delta_sum' => 0,
      'platform_total_certificates' => 0,
      'unenrollments' => 0,
      'platform_custom_completed' => 0,
      'courses_count' => 0,
      'certificates_count' => 0,
      'quantile_count' => 0,
      }
    end
    initialize_with { attributes.as_json }
  end

  factory :course_legacy, class: 'Course::Course' do
    sequence(:course_code) {|n| "course_legacy_#{n}" }
  end

  factory :section_legacy, class: 'Course::Section' do
    association(:course, factory: :course_legacy)
  end

  factory :channel, class: 'Course::Channel' do
    sequence(:code) {|n| "channel-#{n}" }
    title_translations { {'en' => 'English Channel', 'de' => 'Deutscher Channel'} }
    sequence(:position)

    public { true }

    archived { false }
  end

  factory :cluster, class: 'Course::Cluster' do
    sequence(:id) {|n| "category-#{n}" } # rubocop:disable FactoryBot/IdSequence
    sequence(:translations) {|n| {'en' => "Category #{n}", 'de' => "Kategorie #{n}"} }
    sort_mode { 'automatic' }

    trait :visible do
      visible { true }
    end

    # Invisible clusters e.g. for reporting or internal grouping purposes
    trait :invisible do
      visible { false }
    end

    trait :order_automatic do
      sort_mode { 'automatic' }
    end

    trait :order_manual do
      sort_mode { 'manual' }
    end
  end

  factory :classifier, class: 'Course::Classifier' do
    association :cluster
    sequence(:title) {|n| "Classifier #{n}" }
    sequence(:translations) {|n| {'en' => "Classifier ##{n}", 'de' => "Klassifikation ##{n}"} }
    sequence(:descriptions) {|n| {'en' => "Classifier Description ##{n}", 'de' => "Klassifikations-Beschreibung ##{n}"} }
    sequence(:position) {|i| i }
  end

  factory :course, class: 'Course::Course' do
    sequence(:course_code) {|n| "course_#{n}" }
    sequence(:title) {|n| "MOOC on topic #{n}" }
    context_id
    start_date { 2.weeks.ago }
    end_date { 4.weeks.from_now }
    lang { 'en' }
    abstract { 'Abstract text' }
    show_on_list { true }
    proctored { false }
    on_demand { false }

    transient do
      teachers { [] }
    end

    after(:create) do |course, evaluator|
      create(:course_node, course:)

      course.teacher_ids = evaluator.teachers.map do |teacher_name|
        create(:teacher, name: teacher_name).id
      end
      course.save
    end

    trait :featured do
      after(:create) do |course, _|
        cluster = create(:cluster, :invisible, id: 'course-list')
        course.classifiers = Array.wrap(create(:classifier, cluster:, title: 'Featured'))
        course.save
      end
    end

    trait :with_teachers do
      alternative_teacher_text { 'Doctor Who' }
    end

    trait :with_visual do
      transient do
        image_uri { 's3://xikolo-public/courses/123/456/course_visual.png' }
      end

      after(:create) do |course, evaluator|
        create(:visual, course:, image_uri: evaluator.image_uri)
      end
    end

    trait :with_teaser_video do
      transient do
        video { association :video }
      end

      after(:create) do |course, evaluator|
        create(:visual, :with_video, course:, video: evaluator.video)
      end
    end

    trait :preparing do
      status { 'preparation' }
      start_date { 6.months.from_now }
      end_date { 7.months.from_now }
    end

    trait :upcoming do
      status { 'active' }
      start_date { 2.weeks.from_now }
      end_date { 8.weeks.from_now }
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

    trait :self_paced do
      status { 'active' }
      start_date { nil }
      end_date { nil }
    end

    trait :hidden do
      hidden { true }
    end

    trait :external do
      external_course_url { 'https://test.mock/courses/idk' }
    end

    trait :offers_proctoring do
      proctored { true }
    end

    trait :offers_reactivation do
      on_demand { true }
    end

    trait :deleted do
      deleted { true }
    end

    trait :with_channel do
      after(:create) do |course|
        course.channel = create(:channel)
        course.save
      end
    end

    trait :with_skills_metadata do
      after(:create) do |course|
        create(:metadata, :skills, course:)
      end
    end

    trait :with_educational_alignment_metadata do
      after(:create) do |course|
        create(:metadata, :educational_alignment, course:)
      end
    end
  end

  factory :course_node, class: 'Course::Structure::Root' do
    association(:course)
  end

  factory :section, class: 'Course::Section' do
    association(:course)
    after(:create) do |section|
      create(:section_node, section:, course: section.course, parent_id: section.course.node.id)
    end
  end

  factory :section_node, class: 'Course::Structure::Section' do
    association(:section)
    association(:course)
  end

  factory :content_test, class: 'Course::ContentTest' do
    association(:course)
    identifier { 'Gamification' }

    trait :with_forks do
      after(:create) do |content_test|
        create(:fork, content_test:)
      end
    end
  end

  factory :fork, class: 'Course::Fork' do
    association(:section)
    association(:content_test)
    after(:create) do |fork|
      create(:fork_node, fork:, parent_id: fork.section.node.id, course_id: fork.section.course.id)
    end
  end

  factory :fork_node, class: 'Course::Structure::Fork' do
    association(:fork)
  end

  factory :branch, class: 'Course::Branch' do
    association(:fork)
    association(:group)
    after(:create) do |branch|
      create(:branch_node, branch:, parent_id: branch.fork.node.id, course_id: branch.fork.section.course.id)
    end
  end

  factory :branch_node, class: 'Course::Structure::Branch' do
    association(:branch)
  end

  factory :item, class: 'Course::Item' do
    association(:section)
    sequence(:title) {|i| "Item #{i}" }
    after(:create) do |item|
      create(:item_node, item:, course: item.section.course, parent_id: item.section.node.id)
    end

    trait :lti_exercise do
      association :content, factory: :lti_exercise
    end

    trait :richtext do
      association :content, factory: :richtext
    end

    trait :video do
      association :content, factory: :video
    end
  end

  factory :richtext, class: 'Course::Richtext' do
    association(:course)
    text { 'Text' }
  end

  factory :item_node, class: 'Course::Structure::Item' do
    association(:item)
    association(:course)
  end

  factory :result, class: 'Course::Result' do
    association(:item)
    association(:user)
    dpoints { 10 }
  end

  factory :visit, class: 'Course::Visit' do
    association(:item)
    association(:user)
  end

  factory :enrollment, class: 'Course::Enrollment' do
    course
    user_id

    trait :reactivated do
      forced_submission_date { 3.weeks.from_now }
    end

    trait :proctored do
      proctored { true }
    end

    trait :deleted do
      deleted { true }
    end
  end

  factory :teacher, class: 'Course::Teacher' do
    sequence(:name) {|n| "Teacher ##{n}" }
    description { {de: 'Deutsche Biographie', en: 'English bio'} }
    user_id { nil }
  end

  factory :visual, class: 'Course::Visual' do
    association(:course)

    image_uri { 's3://xikolo-public/courses/123/456/course_visual.png' }

    trait :with_video do
      association(:video)
    end
  end

  factory :classifier_assignment, class: 'Course::ClassifierAssignment' do
    association :classifier
    association :course
    sequence(:position) {|n| n }
  end

  factory :metadata, class: 'Course::Metadata' do
    association(:course)
    version { Course::Metadata::VERSION }

    trait :skills do
      name { Course::Metadata::TYPE::SKILLS }
      data do
        JSON.parse(File.read('spec/support/files/course/metadata/skills_valid.json'))
      end
    end

    trait :educational_alignment do
      name { Course::Metadata::TYPE::EDUCATIONAL_ALIGNMENT }
      data do
        JSON.parse(File.read('spec/support/files/course/metadata/educational_alignment_valid.json'))
      end
    end

    trait :license do
      name { Course::Metadata::TYPE::LICENSE }
      data do
        JSON.parse(File.read('spec/support/files/course/metadata/license_valid.json'))
      end
    end

    trait :proprietary_license do
      name { Course::Metadata::TYPE::LICENSE }
      data do
        JSON.parse(File.read('spec/support/files/course/metadata/license_proprietary.json'))
      end
    end
  end

  factory :offer, class: 'Course::Offer' do
    association(:course)

    price { 1000 }
    price_currency { 'EUR' }
    payment_frequency { 'one_time' }
    category { 'course' }
  end
end
