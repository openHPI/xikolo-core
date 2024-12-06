# frozen_string_literal: true

require 'spec_helper'

describe Training, type: :model do
  subject { step }

  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }
  let!(:step)      { assessment.training_step }

  describe '#required_ta_reviews' do
    it 'returns numeric' do
      expect(Training.required_ta_reviews).to be_a(Numeric)
    end

    it 'is greater zero' do
      expect(Training.required_ta_reviews).to be > 0
    end
  end

  describe '.open?' do
    it 'is not opened' do
      expect(step.open?).to be(true)
    end
  end

  describe '.completion' do
    context 'without anything done' do
      it 'has a completion of 0.0' do
        expect(step.completion(SecureRandom.uuid)).to eq(0.0)
      end
    end

    context 'with existing reviews' do
      let(:user_id) { SecureRandom.uuid }

      context 'which are unsubmitted' do
        before do
          2.times do
            shared_submission = create(:shared_submission, :as_submitted, peer_assessment: assessment)
            s = create(:submission, user_id: SecureRandom.uuid, shared_submission:)
            create(:review,
              user_id:,
              step_id: step.id,
              submission_id: s.id,
              optionIDs: get_valid_rubrics(assessment))
          end
        end

        it 'has no completion' do
          expect(step.completion(user_id)).to eq(0.0)
        end
      end

      context 'which are submitted' do
        before do
          3.times do
            shared_submission = create(:shared_submission, :as_submitted, peer_assessment: assessment)
            s = create(:submission, user_id: SecureRandom.uuid, shared_submission:)
            create(:review, :as_submitted,
              user_id:,
              step_id: step.id,
              submission_id: s.id,
              optionIDs: get_valid_rubrics(assessment))
          end
        end

        it 'is completed' do
          expect(step.completion(user_id)).to eq(1.0)
        end
      end
    end
  end

  describe 'advance_team_to_step?' do
    subject { step.advance_team_to_step? }

    it { is_expected.to be_truthy }
  end
end
