# frozen_string_literal: true

require 'spec_helper'

describe 'Types: Any' do
  subject(:type) { Xikolo::Endpoint::Types.make(:any) }

  describe '#out' do
    subject { type.out value }

    context 'with an integer' do
      let(:value) { 42 }

      it { is_expected.to eq value }
    end

    context 'with a float' do
      let(:value) { 4.8 }

      it { is_expected.to eq value }
    end

    context 'with a string' do
      let(:value) { 'hello' }

      it { is_expected.to eq value }
    end

    context 'with the empty string' do
      let(:value) { '' }

      it { is_expected.to eq value }
    end

    context 'with nested types' do
      let(:value) { [{foo: :bar}] }

      it { is_expected.to eq value }
    end

    context 'with true' do
      let(:value) { true }

      it { is_expected.to eq value }
    end

    context 'with false' do
      let(:value) { false }

      it { is_expected.to eq value }
    end

    context 'with nil' do
      let(:value) { nil }

      it { is_expected.to eq value }
    end
  end

  describe '#in' do
    subject { type.in value }

    context 'with an integer' do
      let(:value) { 42 }

      it { is_expected.to eq value }
    end

    context 'with a float' do
      let(:value) { 4.8 }

      it { is_expected.to eq value }
    end

    context 'with a string' do
      let(:value) { 'hello' }

      it { is_expected.to eq value }
    end

    context 'with a string containing a number' do
      let(:value) { '42' }

      it { is_expected.to eq value }
    end

    context 'with the empty string' do
      let(:value) { '' }

      it { is_expected.to eq value }
    end

    context 'with nested types' do
      let(:value) { [{foo: :bar}] }

      it { is_expected.to eq value }
    end

    context 'with true' do
      let(:value) { true }

      it { is_expected.to be true }
    end

    context 'with false' do
      let(:value) { false }

      it { is_expected.to be false }
    end

    context 'with nil' do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end
  end
end
