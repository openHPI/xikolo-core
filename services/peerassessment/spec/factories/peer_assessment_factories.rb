# frozen_string_literal: true

FactoryBot.define do
  factory :peer_assessment do
    title { 'Test Peer Assessment' }
    instructions { 'These are some instructions' }
    grading_hints { 'Some general hints' }
    usage_disclaimer { 'I accept xyz' }
    max_file_size { 5 }
    allowed_attachments { 2 }
    is_team_assessment { false }

    course_id { SecureRandom.uuid }
    item_id { SecureRandom.uuid }

    trait :with_steps do
      after(:create) do |assessment|
        FactoryBot.create(:assignment_submission, peer_assessment: assessment)
        FactoryBot.create(:training, peer_assessment: assessment)
        FactoryBot.create(:peer_grading, peer_assessment: assessment)
        FactoryBot.create(:self_assessment, peer_assessment: assessment)
        FactoryBot.create(:results, peer_assessment: assessment)
      end
    end

    trait :with_rubrics do
      after(:create) do |assessment|
        FactoryBot.create(:rubric, :with_random_options, peer_assessment: assessment)
        FactoryBot.create(:rubric, :with_random_options, peer_assessment: assessment)
        FactoryBot.create(:rubric, :with_random_options, peer_assessment: assessment)
      end
    end

    # Create a rubric with options with one, two and three points.
    # Used for deterministic grade testing.
    trait :with_one_rubric do
      after(:create) do |assessment|
        assessment.rubrics << FactoryBot.create(:rubric, :with_deterministic_options, peer_assessment: assessment)
      end
    end

    # Create rubrics with options with one to six points.
    # Used to test if a grade is eligible for a regrading request
    trait :with_many_rubrics do
      after(:create) do |assessment|
        assessment.rubrics << FactoryBot.create(:rubric, :with_many_deterministic_options, peer_assessment: assessment)
        assessment.rubrics << FactoryBot.create(:rubric, :with_many_deterministic_options, peer_assessment: assessment)
        assessment.rubrics << FactoryBot.create(:rubric, :with_many_deterministic_options, peer_assessment: assessment)
      end
    end

    # Create rubrics with options with one to six points.
    # Used to test if a grade is eligible for a regrading request
    trait :with_rubrics_with_identical_points_for_each_option do
      after(:create) do |assessment|
        assessment.rubrics << FactoryBot.create(:rubric, :with_options_that_provide_identical_points, peer_assessment: assessment)
        assessment.rubrics << FactoryBot.create(:rubric, :with_options_that_provide_identical_points, peer_assessment: assessment)
        assessment.rubrics << FactoryBot.create(:rubric, :with_options_that_provide_identical_points, peer_assessment: assessment)
      end
    end

    trait :with_deterministic_rubrics do
      after(:create) do |assessment|
        assessment.rubrics << FactoryBot.create(:rubric, :with_deterministic_options, peer_assessment: assessment)
        assessment.rubrics << FactoryBot.create(:rubric, :with_deterministic_options, peer_assessment: assessment)
        assessment.rubrics << FactoryBot.create(:rubric, :with_deterministic_options, peer_assessment: assessment)
      end
    end

    trait :as_team_assessment do
      is_team_assessment { true }
    end
  end
end
