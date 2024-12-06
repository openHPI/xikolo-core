# frozen_string_literal: true

require 'spec_helper'

describe PeerGrading, type: :model do
  subject { step }

  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }
  let!(:step)      { assessment.steps[2] }

  describe '.completion' do
    let(:user_id) { SecureRandom.uuid }

    context 'with no reviews' do
      it 'has a completion of 0%' do
        expect(step.completion(user_id)).to eq(0.0)
      end
    end

    context 'with unsubmitted reviews' do
      before do
        2.times do
          shared_submission = create(:shared_submission, :as_submitted, peer_assessment: assessment)
          s = create(:submission, :with_pool_entries, user_id: SecureRandom.uuid, shared_submission:)
          create(:review, user_id:, step_id: step.id, submission_id: s.id)
        end
      end

      it 'has no progress at all' do
        expect(step.completion(user_id)).to eq(0.0)
      end
    end

    context 'with two submitted reviews' do
      before do
        2.times do
          shared_submission = create(:shared_submission, :as_submitted, peer_assessment: assessment)
          s = create(:submission, :with_pool_entries, user_id: SecureRandom.uuid, shared_submission:)
          create(:review, :as_submitted,
            user_id:,
            step_id: step.id,
            submission_id: s.id,
            optionIDs: get_valid_rubrics(assessment))
        end
      end

      it 'has 2/3 progress' do
        expect(step.completion(user_id)).to be_within(0.1).of(0.6)
      end
    end

    context 'with all submitted reviews' do
      before do
        3.times do
          shared_submission = create(:shared_submission, :as_submitted, peer_assessment: assessment)
          s = create(:submission, :with_pool_entries, user_id: SecureRandom.uuid, shared_submission:)
          create(:review, :as_submitted,
            user_id:,
            step_id: step.id,
            submission_id: s.id,
            optionIDs: get_valid_rubrics(assessment))
        end
      end

      it 'has 100% progress' do
        expect(step.completion(user_id)).to eq(1.0)
      end
    end
  end

  describe 'advance_team_to_step?' do
    subject { step.advance_team_to_step? }

    context 'with training step' do
      it { is_expected.to be_falsey }
    end

    context 'without training step' do
      before { assessment.training_step.destroy }

      it { is_expected.to be_truthy }
    end
  end
end
