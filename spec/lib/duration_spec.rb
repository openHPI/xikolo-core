# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Duration do
  subject(:duration) { described_class.new(total_seconds) }

  context 'when total seconds are given' do
    let(:total_seconds) { 90 }

    describe '#minutes' do
      it 'calculates the minutes correctly' do
        expect(duration.minutes).to eq 1
      end

      context 'when total seconds are multiple hours' do
        let(:total_seconds) { 7500 }

        it 'calculates the minutes remainder correctly' do
          expect(duration.minutes).to eq 5
        end
      end
    end

    describe '#seconds' do
      it 'calculates the seconds remainder correctly' do
        expect(duration.seconds).to eq 30
      end
    end

    describe '#to_s' do
      it 'formats total seconds in human-readable string' do
        expect(duration.to_s).to eq '1m 30s'
      end

      context 'when total seconds are more than one hour' do
        let(:total_seconds) { 3665 }

        it 'returns hour, minutes and seconds correctly' do
          expect(duration.to_s).to eq '1h 1m 5s'
        end
      end

      context 'when total seconds are less than one minute' do
        let(:total_seconds) { 35 }

        it 'skips hours and minutes' do
          expect(duration.to_s).to eq '35s'
        end
      end

      context 'when the total seconds is 0' do
        let(:total_seconds) { 0 }

        it 'returns 0 seconds' do
          expect(duration.to_s).to eq '0s'
        end
      end

      context 'when the total seconds is nil' do
        let(:total_seconds) { nil }

        it 'returns 0 seconds' do
          expect(duration.to_s).to eq '0s'
        end
      end
    end
  end
end
