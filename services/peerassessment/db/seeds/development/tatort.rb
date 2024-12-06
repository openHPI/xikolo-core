# frozen_string_literal: true

assessment = PeerAssessment.create!(
  id: '00000001-5300-4444-9999-000000002001',
  title: 'Team Peer Assessment',
  course_id: '00000001-3300-4444-9999-000000002001',
  item_id: '00000003-3300-4444-9999-000000002001',
  allowed_attachments: 1,
  allowed_file_types: '.pdf',
  instructions: 'Some instructions for the team peer assessment',
  grading_hints: 'Some hints.',
  is_team_assessment: true
)

# Steps
assessment.steps.create!(
  type: 'AssignmentSubmission',
  position: 1
)

assessment.steps.create!(
  type: 'Training',
  position: 2,
  required_reviews: 1
)

assessment.steps.create!(
  type: 'PeerGrading',
  position: 3,
  required_reviews: 3
)

assessment.steps.create!(
  type: 'SelfAssessment',
  position: 4
)

assessment.steps.create!(
  type: 'Results',
  position: 5
)

# Rubrics and corresponding options
rubric = assessment.rubrics.create!(
  title: 'Fall gelöst?',
  hints: 'Mörder gefasst?',
  position: 0
)

rubric.rubric_options.create!(
  description: 'Ja',
  points: 2
)

rubric.rubric_options.create!(
  description: 'Noch nicht',
  points: 1
)

rubric.rubric_options.create!(
  description: 'Welcher Fall?',
  points: 0
)

assessment.rubrics.create!(
  title: 'Social Skills',
  team_evaluation: true,
  position: 0 # TODO: Is this correct?
)

assessment.rubrics.create!(
  title: 'Contribution',
  team_evaluation: true,
  position: 1
)

assessment.rubrics.create!(
  title: 'Organization',
  team_evaluation: true,
  position: 2
)

[
  %w[00000001-3100-4444-9999-000000002008 00000001-3100-4444-9999-000000002009], # Team Dortmund: Faber, Bönisch
  %w[00000001-3100-4444-9999-000000002006 00000001-3100-4444-9999-000000002002], # Team Münster: Thiel, Börne
  %w[00000001-3100-4444-9999-000000002001 00000001-3100-4444-9999-000000002010], # Team Berlin: Ritter, Stark
  %w[00000001-3100-4444-9999-000000002005 00000001-3100-4444-9999-000000002007], # Team Wien: Fellner, Eisner
  %w[00000001-3100-4444-9999-000000002003 00000001-3100-4444-9999-000000002004], # Team Kiel: Borowski, Brandt
  ['00000001-3100-4444-9999-000000000002', nil], # Admins: Administrator
].each do |user1, user2|
  group = Group.create!

  assessment.participants.create!(
    group:,
    user_id: user1
  )

  next if user2.nil?

  assessment.participants.create!(
    group:,
    user_id: user2
  )
end
