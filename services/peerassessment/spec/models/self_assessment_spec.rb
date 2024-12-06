# frozen_string_literal: true

require 'spec_helper'

describe SelfAssessment, type: :model do
  subject { step }

  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }
  let(:user_id)    { SecureRandom.uuid }
  let(:shared_submission) { create(:shared_submission, :as_submitted, peer_assessment_id: assessment.id) }
  let!(:submission) { create(:submission, user_id:, shared_submission:) }
  let!(:step) { assessment.steps[-2] }

  describe 'validity' do
    it 'is valid' do
      expect(step).to be_valid
    end
  end

  describe '.completion' do
    context 'with no review' do
      it 'has no progress at all' do
        expect(step.completion(user_id)).to eq(0)
      end
    end

    context 'with an existing self-review' do
      context 'which is not submitted' do
        before do
          create(:review,
            user_id:,
            submission_id: submission.id,
            optionIDs: get_valid_rubrics(assessment),
            step_id: step.id)
        end

        it 'has no progress at all' do
          expect(step.completion(user_id)).to eq(0)
        end
      end

      context 'which is submitted' do
        before do
          create(:review, :as_submitted,
            user_id:,
            submission_id: submission.id,
            optionIDs: get_valid_rubrics(assessment),
            step_id: step.id)
        end

        it 'is completed' do
          expect(step.completion(user_id)).to eq(1.0)
        end
      end
    end
  end
end
