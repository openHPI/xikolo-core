# frozen_string_literal: true

require 'spec_helper'

describe AssignmentSubmission, type: :model do
  subject { step }

  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }
  let!(:step)      { assessment.steps[0] }
  let(:user_id) { SecureRandom.uuid }
  let(:group) { create(:group) }
  let!(:participant) { create(:participant, peer_assessment: assessment, user_id:, group:) }

  let(:shared_submission) { create(:shared_submission, peer_assessment_id: assessment.id) }
  let(:submission) { create(:submission, user_id:, shared_submission:) }

  describe '.completion' do
    context 'without an existing submission' do
      it 'has a completion of 0.0' do
        expect(step.completion(SecureRandom.uuid)).to eq(0.0)
      end
    end

    context 'with an existing submission' do
      context 'which is unsubmitted' do
        it 'stills not have a completion of 100%' do
          expect(step.completion(user_id)).to eq(0.0)
        end
      end

      context 'which is submitted' do
        before do
          submission
          shared_submission.update submitted: true
        end

        it 'has a completion of 100%' do
          expect(step.completion(user_id)).to eq(1.0)
        end
      end
    end
  end

  describe 'advance_team_to_step?' do
    subject { step.advance_team_to_step? }

    it { is_expected.to be_truthy }
  end

  describe 'on_step_enter' do
    subject(:on_enter) { step.on_step_enter user_id }

    it 'creates a submission' do
      expect { on_enter }.to change(Submission, :count).by(1)
    end

    context 'with exiting submission' do
      before { submission }

      it 'does not create a submission' do
        expect { on_enter }.not_to change(Submission, :count)
      end
    end

    context 'with team members' do
      before do
        create_list(:participant, 3,
          peer_assessment: assessment,
          group_id: participant.group_id)
      end

      it 'creates a submission for the user and all team members' do
        expect { on_enter }.to change(Submission, :count).by(4)
      end
    end
  end
end
