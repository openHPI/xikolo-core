# frozen_string_literal: true

require 'spec_helper'

describe Statistic, type: :model do
  subject { statistic }

  let!(:statistic) { described_class.new(peer_assessment_id: assessment.id, concern: 'training') }
  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }
  let(:user_id) { SecureRandom.uuid }
  let(:params) do
    {
      user_id:,
    }
  end

  context 'without anything done for the assessment' do
    it 'has zero available submissions' do
      expect(statistic.available_submissions).to eq(0)
    end

    it 'has no reviews done' do
      expect(statistic.finished_reviews).to eq(0)
    end

    it 'has five required reviews' do
      expect(statistic.required_reviews).to eq(5.0)
    end
  end

  context 'with some work done' do
    before do
      assessment = PeerAssessment.take
      5.times do
        shared_s = create(:shared_submission,
          :as_submitted,
          peer_assessment_id: assessment.id)

        s = create(:submission,
          user_id: SecureRandom.uuid,
          shared_submission: shared_s)

        leftover = create(:submission,
          user_id: SecureRandom.uuid,
          shared_submission: shared_s)

        leftover.handle_training_pool_entry

        create(:review, :as_submitted, :as_train_review,
          submission_id: s.id,
          step: assessment.steps[1],
          optionIDs: get_valid_rubrics(assessment),
          user_id: SecureRandom.uuid)
      end

      statistic.reload params
    end

    it 'indicates the work done' do
      expect(statistic.finished_reviews).to eq(5)
    end

    it 'has some submissions left' do
      expect(statistic.available_submissions).to eq(5)
    end
  end

  context 'with everything done for the training' do
    before do
      assessment = PeerAssessment.take!
      fulfill_training_requirements assessment, assessment.steps[1]
      statistic.reload params
    end

    it 'has all reviews done' do
      expect(statistic.finished_reviews).to be >= Training.required_ta_reviews
    end
  end
end
