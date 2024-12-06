# frozen_string_literal: true

require 'spec_helper'

describe SharedSubmission, type: :model do
  subject { shared_submission }

  let(:assessment) { create(:peer_assessment, :with_steps) }
  let(:shared_submission) { build(:shared_submission, params.merge(peer_assessment: assessment)) }
  let(:params) { {} }

  describe 'validity' do
    it { is_expected.to be_valid }

    describe '.ensure_unsubmitted' do
      it 'invalidates the record if it is already submitted' do
        shared_submission.submitted = true
        shared_submission.save!

        shared_submission.reload.text = 'New Text'
        expect(shared_submission).not_to be_valid
      end
    end
  end
end
