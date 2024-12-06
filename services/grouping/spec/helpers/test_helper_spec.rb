# frozen_string_literal: true

require 'spec_helper'

describe TestHelper, type: :helper do
  describe '#binomial_test' do
    context 'exact' do
      it 'calculates the right statistic' do
        statistic = helper.binomial_test([0.5], ([1] * 8) + ([0] * 2), tail: 'both')[:statistic]
        expect(statistic).to eq 8
      end

      it 'calculates the right p value' do
        p_value = helper.binomial_test([0.5], ([1] * 8) + ([0] * 2), tail: :left)[:p_value]
        expect(p_value).to be_within(0.01).of(0.989)

        p_value = helper.binomial_test([0.5], ([1] * 8) + ([0] * 2), tail: :right)[:p_value]
        expect(p_value).to be_within(0.01).of(0.054)

        p_value = helper.binomial_test([0.5], ([1] * 8) + ([0] * 2), tail: :both)[:p_value]
        expect(p_value).to be_within(0.01).of(0.109)
      end
    end

    context 'approximate' do
      it 'calculates the right statistic' do
        statistic = helper.binomial_test([0.1], ([1] * 21) + ([0] * 99))[:statistic]
        expect(statistic).to be_within(0.01).of(2.737)
      end
    end
  end

  describe '#two_sample_t' do
    it 'calculates the right statistic' do
      statistic = helper.two_sample_t([17] * 5, [19.2, 17.4, 18.5, 16.5, 18.9])[:statistic]
      expect(statistic).to be_within(0.01).of(2.186)
    end

    it 'calculates the right p-value' do
      p_value = helper.two_sample_t([17] * 5, [19.2, 17.4, 18.5, 16.5, 18.9], tail: :left)[:p_value]
      expect(p_value).to be_within(0.01).of(0.953)

      p_value = helper.two_sample_t([17] * 5, [19.2, 17.4, 18.5, 16.5, 18.9], tail: :right)[:p_value]
      expect(p_value).to be_within(0.01).of(0.047)

      p_value = helper.two_sample_t([17] * 5, [19.2, 17.4, 18.5, 16.5, 18.9], tail: :both)[:p_value]
      expect(p_value).to be_within(0.01).of(0.094)
    end

    context 'with variance of zero' do
      it 'returns no p-value' do
        p_value = helper.two_sample_t([0] * 5, [0] * 5)[:p_value]
        expect(p_value).to be_nil
      end
    end
  end

  describe '#effect_size' do
    subject(:calculated_effect_size) { effect_size x, y, type: }

    context 'binomial' do
      let(:type) { :binomial }
      let(:x) { [1, 1, 0, 0, 1] }
      let(:y) { [0, 0, 1, 1, 0] }

      it { is_expected.to be_within(0.01).of(0.4) }
    end

    context 'normal' do
      let(:type) { :normal }
      let(:x) { [17] * 5 }
      let(:y) { [19.2, 17.4, 18.5, 16.5, 18.9] }

      it { is_expected.to be_within(0.01).of(1.38) }
    end

    context 'other' do
      let(:type) { :foo }
      let(:x) { [17] * 5 }
      let(:y) { [19.2, 17.4, 18.5, 16.5, 18.9] }

      it 'raises error' do
        expect { calculated_effect_size }.to raise_error ArgumentError
      end
    end
  end
end
