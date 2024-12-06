# frozen_string_literal: true

course = Course::Create.call(
  title: 'Content A/B',
  description: <<~DESCRIPTION.squish,
    This course utilizes the Content A/B features based on the new course
    content tree.
  DESCRIPTION
  course_code: 'content-ab',
  lang: 'en',
  status: 'active',
  start_date: 10.days.ago,
  end_date: 4.weeks.from_now
)

# Create root node to mark this as a "new" course (with the content tree used for ordering)
Structure::Root.create!(course:)

section1 = course.sections.create!(
  title: 'Week 1',
  description: 'Week 1',
  published: true
)

section2 = course.sections.create!(
  title: 'Week 2',
  description: 'Week 2'
)

section1.items.create!(
  title: 'Week 1: Question 1',
  content_type: 'quiz',
  content_id: '00000001-3800-4444-9999-000000000001',
  exercise_type: 'main',
  max_dpoints: 100
)

item1_2a1 = section1.items.create!(
  title: 'Week 1: Question 2.1 (Branch A)',
  content_type: 'quiz',
  content_id: '00000001-3800-4444-9999-000000000001',
  exercise_type: 'main',
  max_dpoints: 70
)

item1_2a2 = section1.items.create!(
  title: 'Week 1: Question 2.2 (Branch A)',
  content_type: 'quiz',
  content_id: '00000001-3800-4444-9999-000000000001',
  exercise_type: 'main',
  max_dpoints: 90
)

item1_2b1 = section1.items.create!(
  title: 'Week 1: Question 2 (Branch B)',
  content_type: 'quiz',
  content_id: '00000001-3800-4444-9999-000000000001',
  exercise_type: 'main',
  max_dpoints: 50
)

section2.items.create!(
  title: 'Week 2: Question 1',
  content_type: 'quiz',
  content_id: '00000001-3800-4444-9999-000000000001',
  exercise_type: 'main',
  max_dpoints: 60
)

content_test1 = course.content_tests.create!(
  identifier: 'gamification',
  groups: %w[without-game with-game]
)

fork1 = section1.forks.create!(
  title: 'The Fork',
  content_test: content_test1
)

# Move a few items inside these branches
item1_2a1.node.move_to_child_of(fork1.branches[0].node)
item1_2a2.node.move_to_child_of(fork1.branches[0].node)
item1_2b1.node.move_to_child_of(fork1.branches[1].node)
