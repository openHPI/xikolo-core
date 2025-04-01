# frozen_string_literal: true

course = Course::Create.call(
  id: '00000001-3300-4444-9999-000000002001',
  title: 'Team Peer Assessments',
  description: 'A little bit more of text.',
  course_code: 'tatort',
  lang: 'en',
  status: 'active',
  start_date: 10.days.ago,
  end_date: 4.weeks.from_now
)

section = course.sections.create!(
  title: 'Week 1',
  description: 'Week 1',
  published: true
)

section.items.create!(
  id: '00000003-3300-4444-9999-000000002001',
  title: 'Test Peer Assessment',
  start_date: 10.days.ago,
  end_date: 4.weeks.from_now,
  content_type: 'peer_assessment',
  exercise_type: 'main',
  content_id: '00000001-5300-4444-9999-000000002001',
  show_in_nav: true
)

##### Enrollments #####

# Team members

user_ids = %w[
  00000001-3100-4444-9999-000000002001
  00000001-3100-4444-9999-000000002002
  00000001-3100-4444-9999-000000002003
  00000001-3100-4444-9999-000000002004
  00000001-3100-4444-9999-000000002005
  00000001-3100-4444-9999-000000002006
  00000001-3100-4444-9999-000000002007
  00000001-3100-4444-9999-000000002008
  00000001-3100-4444-9999-000000002009
  00000001-3100-4444-9999-000000002010
]

user_ids.each do |user_id|
  course.enrollments.create!(user_id:)
end
