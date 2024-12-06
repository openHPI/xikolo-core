# frozen_string_literal: true

require 'spec_helper'

describe Poll::Option, type: :model do
  let(:poll) { create(:poll, :current) }

  describe '(updating)' do
    subject(:update) { option.update(attrs) }

    let(:option) { poll.options.first }
    let(:previous_position) { option.position }

    context 'with its current position' do
      let(:attrs) { {position: previous_position} }

      it { is_expected.to be true }

      # We test this to make sure that the UPDATE query that updates other
      # options' positions does not mess with the position of this option.
      it 'does not change the position' do
        update
        expect(option).to have_attributes position: previous_position
      end
    end

    describe 'based on poll state' do
      let(:attrs) { {text: 'typo fixed'} }

      context 'when poll is not yet open' do
        let(:poll) { create(:poll, :future) }

        it { is_expected.to be true }
      end

      context 'when poll has started' do
        let(:poll) { create(:poll, :current) }

        it { is_expected.to be true }
      end

      context 'when poll has ended' do
        let(:poll) { create(:poll, :past) }

        it { is_expected.to be true }
      end
    end
  end

  describe '(deleting)' do
    subject { option.destroy }

    let(:option) { poll.options.first }

    describe 'based on poll state' do
      context 'when poll is not yet open' do
        let(:poll) { create(:poll, :future) }

        it { is_expected.to be_truthy }
      end

      context 'when poll has started' do
        let(:poll) { create(:poll, :current) }

        it { is_expected.to be_falsey }
      end

      context 'when poll has ended' do
        let(:poll) { create(:poll, :past) }

        it { is_expected.to be_falsey }
      end
    end
  end
end
