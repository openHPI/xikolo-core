# frozen_string_literal: true

module TrainingSpecHelper
  include ReviewHelper

  def fulfill_training_requirements(assessment, training_step)
    # 20 random submissions, all submitted
    submissions = []

    20.times do
      shared = FactoryBot.create(:shared_submission, :as_submitted, peer_assessment_id: assessment.id)
      submissions << FactoryBot.create(:submission, user_id: SecureRandom.uuid, shared_submission: shared)
    end

    ta_id = SecureRandom.uuid

    # 20 random submitted training sample reviews
    20.times do
      FactoryBot.create(:review, :as_train_review, :as_submitted,
        user_id: ta_id,
        submission_id: submissions.pop.id,
        step_id: training_step.id,
        optionIDs: get_valid_rubrics(assessment))
    end
  end

  def get_valid_rubrics(peer_assessment)
    peer_assessment.rubrics.map do |rubric|
      rubric.rubric_options.sample.id
    end
  end
end
