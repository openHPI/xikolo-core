# frozen_string_literal: true

FactoryBot.define do
  factory :submission do
    transient do
      submitted { false }
      association :peer_assessment
    end

    user_id { SecureRandom.uuid }
    shared_submission do
      association :shared_submission, peer_assessment:, submitted:
    end

    trait :with_pool_entries do
      after(:create) do |submission|
        submission.handle_training_pool_entry
        submission.handle_grading_pool_entry
        # TODO: this creates a loop
        # When deadlines of reviews lie in the future the worker is rescheduled
        # hence `drain` never stops
        # ReviewCleanupWorker.drain
      end
    end

    trait :with_nominations do
      transient do
        nominations { 1 }
      end

      after(:create) do |submission, evaluator|
        evaluator.nominations.times do
          create(:review, :as_submitted,
            award: true,
            step_id: evaluator.peer_assessment.grading_step.id,
            submission:)
        end
      end
    end

    trait :with_grade do
      transient do
        points { 3.0 }
      end

      # This needs to happen after build as the Submission#create_grade_object
      # after_create callback would kick in instead
      after(:build) do |submission, evaluator|
        submission.grade = create(:grade, base_points: evaluator.points, submission:)
      end
    end

    trait :with_avg_rating do
      transient do
        rating { 3 } # Between 0 and 5
      end

      after(:create) do |submission, evaluator|
        FactoryBot.create(:gallery_vote,
          shared_submission: submission.shared_submission,
          rating: evaluator.rating)
      end
    end
  end
end
