# frozen_string_literal: true

require 'spec_helper'

describe SampleSizeHelper, type: :helper do
  describe '#sample_size' do
    subject(:sample_size) { helper.sample_size es, type }

    let(:es) { 0.2 }

    context 'normal' do
      let(:type) { :normal }

      it { is_expected.to eq 310 }
    end

    context 'binomial' do
      let(:type) { :binomial }

      it { is_expected.to eq 154 }
    end

    context 'other' do
      let(:type) { :foo }

      it 'raises error' do
        expect { sample_size }.to raise_error ArgumentError
      end
    end
  end
end
