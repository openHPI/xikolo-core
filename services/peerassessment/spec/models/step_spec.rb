# frozen_string_literal: true

require 'spec_helper'

describe Step, type: :model do
  context 'with a single step' do
    subject { step }

    let!(:step) { Step.new peer_assessment_id: SecureRandom.uuid, type: 'Step', deadline: 1.day.from_now, position: 1 }

    describe '.open?' do
      it 'is open' do
        expect(step.open?).to be(true)
      end
    end

    describe '.completion' do
      it 'raises an exception' do
        expect { step.completion SecureRandom.uuid }.to raise_error(NotImplementedError)
      end
    end

    describe '.complete?' do
      it 'raises an exception' do
        expect { step.complete? SecureRandom.uuid }.to raise_error(NotImplementedError)
      end
    end
  end

  context 'within a full workflow' do
    subject { steps }

    before { create(:peer_assessment, :with_steps) }

    let(:steps) { Step.all } # For some reason, I have to fetch steps without going through the assoc.

    describe '.next_step' do
      it 'returns the second step when called on the first one' do
        expect(steps.first.next_step).to eq steps[1]
      end

      context 'on the last step' do
        it 'returns nil' do
          expect(steps.last.next_step).to be_nil
        end
      end
    end

    describe '.previous_step' do
      it 'returns the first step when called on the second one' do
        expect(steps[1].previous_step).to eq steps.first
      end

      context 'on the first step' do
        it 'returns nil' do
          expect(steps.first.previous_step).to be_nil
        end
      end
    end
  end
end
