# frozen_string_literal: true

require 'spec_helper'

describe Submission, type: :model do
  subject { submission }

  let(:assessment) { create(:peer_assessment, :with_steps) }
  let(:user_id) { SecureRandom.uuid }
  let(:shared_submission) { create(:shared_submission, peer_assessment: assessment) }
  let!(:submission) { create(:submission, shared_submission:, user_id:) }

  describe 'validity' do
    it { is_expected.to be_valid }

    it { is_expected.to accept_values_for(:shared_submission, shared_submission) }
    it { is_expected.not_to accept_values_for(:shared_submission, nil) }

    it { is_expected.to accept_values_for(:user_id, user_id) }
    it { is_expected.not_to accept_values_for(:user_id, nil) }

    describe 'user uniqueness' do
      before { new_submission.valid? }

      context 'per submission' do
        let(:new_submission) { build(:submission, shared_submission:, user_id:) }

        it { expect(new_submission.errors[:user_id]).to include('has already been taken') }
      end

      context 'per peer assessment' do
        let(:new_shared_submission) { create(:shared_submission, peer_assessment: assessment) }
        let(:new_submission) { build(:submission, shared_submission: new_shared_submission, user_id:) }

        it { expect(new_submission.errors[:user_id]).to include('has already a submission for this assessment') }
      end
    end
  end

  describe '.handle_training_pool_entry' do
    it 'creates a training pool entry' do
      expect do
        submission.handle_training_pool_entry
      end.to change(PoolEntry.all, :size).from(0).to(1)
    end

    it 'does not create a training pool entry if the submission is a disallowed sample' do
      training_pool = assessment.resource_pools.find_by(purpose: 'training')
      submission.disallowed_sample = true
      submission.shared_submission.save

      expect do
        submission.reload.handle_training_pool_entry
      end.not_to change(PoolEntry.where(resource_pool_id: training_pool.id), :size)
    end
  end

  describe 'participants' do
    subject { submission.participants }

    let(:participant) { create(:participant, user_id:, peer_assessment: assessment) }

    it { is_expected.to eq [participant] }
  end

  describe '.nominations' do
    context 'submission is nominated for award' do
      before do
        expect(assessment.steps[2]).to be_a PeerGrading
        create(:review, :as_submitted, submission:, award: true, step: assessment.steps[2], user_id: SecureRandom.uuid)
      end

      context 'submission is reported' do
        subject { submission.nominations }

        before do
          # nominations for submissions that are reported are not taken into account
          create(:review, :suspended, :as_submitted, submission:, award: true, step: assessment.steps[2], user_id: SecureRandom.uuid)
        end

        it { is_expected.to eq 1 }
      end

      context 'review is reported' do
        subject { submission.nominations }

        before do
          # however, if a participant reports a review that nominated her, this nomination will still be counted
          create(:review, :accused, :as_submitted, submission:, award: true, step: assessment.steps[2], user_id: SecureRandom.uuid)
        end

        it { is_expected.to eq 2 }
      end
    end
  end
end
