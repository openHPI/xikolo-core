# frozen_string_literal: true

course = Course::Create.call(
  id: '00000001-3300-4444-9999-000000000008',
  title: 'Proctoring with SMOWL',
  description: <<~DESCRIPTION.squish,
    This course features proctored exams.
  DESCRIPTION
  context_id: '81e01000-3100-4444-a002-000000000008',
  course_code: 'smowl-proctoring',
  lang: 'en',
  status: 'active',
  proctored: true,
  start_date: 10.days.ago,
  end_date: 4.weeks.from_now
)

section1 = course.sections.create!(
  title: 'Week 1',
  description: 'Week 1',
  published: true
)

course.sections.create!(
  title: 'Week 2',
  description: 'Week 2'
)

section1.items.create!(
  title: 'Quiz 1',
  content_type: 'quiz',
  content_id: '00000001-3800-4444-9999-000000000001',
  exercise_type: 'main',
  max_dpoints: 100,
  proctored: true,
  submission_deadline: 3.weeks.from_now
)

# Enroll admin and enable proctoring
Enrollment::Create.call(
  '00000001-3100-4444-9999-000000000002',
  course,
  proctored: true
)
