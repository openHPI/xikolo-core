# frozen_string_literal: true

FactoryBot.define do
  factory 'peerassessment:root', class: Hash do
    peer_assessments_url { '/peer_assessments{?course_id}' }
    peer_assessment_url { '/peer_assessments/{id}' }
    shared_submission_url { '/shared_submissions/{id}' }

    initialize_with { attributes.as_json }
  end

  factory 'peerassessment:peerassessment', class: Hash do
    id { generate(:uuid) }
    title { 'Test Peer Assessment' }
    instructions { 'These are some instructions' }
    max_points { 10 }
    grading_hints { 'Some general hints' }
    usage_disclaimer { 'I accept xyz' }
    max_file_size { 5 }
    allowed_attachments { 2 }
    is_team_assessment { false }

    course_id { generate(:course_id) }
    item_id { generate(:item_id) }

    initialize_with { attributes.as_json }
  end

  factory 'peerassessment:statistic', class: Hash do
    available_submissions { 5 }
    submissions_with_content { 5 }
    submitted_submissions { 5 }
    conflicts { 0 }
    point_groups { [['submission_create', [['2014-10-24', 1]]], ['submission_submit', [['2016-06-09', 1]]]] }

    initialize_with { attributes.as_json }
  end
end
