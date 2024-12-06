# frozen_string_literal: true

require 'spec_helper'

describe Results, type: :model do
  subject(:step) { assessment.steps.last }

  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }

  it { is_expected.to be_valid }

  describe '.completion' do
    let(:user_id) { SecureRandom.uuid }

    context 'when the step is still open' do
      it 'has no progress at all' do
        expect(step.completion(user_id)).to eq(0)
      end
    end

    context 'when the deadline has passed' do
      before { step.update(deadline: 1.day.ago) }

      # Reasoning: This is the last step, and rating of reviews is always optional.
      it 'is always considered complete' do
        expect(step.completion(user_id)).to eq(1.0)
      end
    end
  end
end
