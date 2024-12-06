# frozen_string_literal: true

require 'spec_helper'

describe Proctoring::Result do
  subject(:result) do
    described_class.new(
      features, thresholds:
    )
  end

  let(:features) { {'morepeople' => 2, 'covered' => 1} }
  let(:thresholds) { {'morepeople' => 5, 'covered' => 3} }

  describe '#add' do
    subject(:sum) { result.add other_features }

    let(:thresholds) { {'morepeople' => 5, 'covered' => 3, 'wrongimage' => 1, 'cheat' => 0} }
    let(:other_features) do
      {'morepeople' => 0, 'covered' => 1, 'wrongimage' => 1}
    end

    it { is_expected.to be_a described_class }

    it 'calculates the accumulated values for all criteria' do
      expect(sum.features).to eq(
        'morepeople' => 2,
        'covered' => 2,
        'wrongimage' => 1,
        'cheat' => 0
      )
    end

    context 'adding an empty result' do
      let(:other_features) { {} }

      it 'does not change any features' do
        expect(sum.features).to match_array result.features
      end
    end
  end

  describe '#empty?' do
    subject { result.empty? }

    it { is_expected.to be false }

    context 'for an empty result' do
      let(:features) { {} }

      it { is_expected.to be true }
    end
  end

  describe '#perfect?' do
    subject { result.perfect? }

    it { is_expected.to be false }

    context 'for an empty result' do
      let(:features) { {} }

      it { is_expected.to be true }
    end
  end

  describe '#issues?' do
    subject { result.issues? }

    it { is_expected.to be true }

    context 'for an empty result' do
      let(:features) { {} }

      it { is_expected.to be false }
    end
  end

  describe '#max' do
    subject { result.max }

    it { is_expected.to eq 2 }

    context 'for an empty result' do
      let(:features) { {} }

      it { is_expected.to eq 0 }
    end
  end

  describe '#valid?' do
    subject { result.valid? }

    let(:thresholds) { {'morepeople' => 5} }

    context 'when above a threshold' do
      let(:features) { {'morepeople' => 12} }

      it { is_expected.to be false }
    end

    context 'when exactly at a threshold' do
      let(:features) { {'morepeople' => 5} }

      it { is_expected.to be false }
    end

    context 'when below a threshold' do
      let(:features) { {'morepeople' => 3} }

      it { is_expected.to be true }
    end

    context 'when at a threshold that is zero' do
      let(:features) { {'morepeople' => 0} }
      let(:thresholds) { {'morepeople' => 0} }

      it { is_expected.to be true }
    end
  end

  describe '#to_json' do
    subject(:serialized) { result.to_json }

    let(:features) { {'morepeople' => 2, 'covered' => 1} }
    let(:thresholds) { {'nobody' => 0, 'wronguser' => 0, 'morepeople' => 0} }

    it { is_expected.to be_a String }

    describe '(json)' do
      subject(:parsed) { JSON.parse serialized }

      it { is_expected.to be_an Array }

      it 'includes all known criteria' do
        expect(parsed.map(&:first)).to match_array %w[
          nobody wronguser morepeople
        ]
      end
    end
  end
end
