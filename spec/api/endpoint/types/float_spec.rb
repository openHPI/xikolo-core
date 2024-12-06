# frozen_string_literal: true

require 'spec_helper'

describe 'Types: Float' do
  subject(:type) { Xikolo::Endpoint::Types.make(:float) }

  describe '#out' do
    subject(:result) { type.out value }

    context 'with an integer' do
      let(:value) { 42 }

      it 'converts the integer to float' do
        expect(result).to eq 42.0
      end
    end

    context 'with a float' do
      let(:value) { 4.8 }

      it 'returns that float' do
        expect(result).to eq 4.8
      end
    end

    context 'with a string' do
      let(:value) { 'hello' }

      it { is_expected.to eq 0.0 }
    end

    context 'with the empty string' do
      let(:value) { '' }

      it { is_expected.to eq 0.0 }
    end

    context 'with nested types' do
      let(:value) { [{foo: :bar}] }

      it { is_expected.to eq 0.0 }
    end

    context 'with true' do
      let(:value) { true }

      it { is_expected.to eq 0.0 }
    end

    context 'with false' do
      let(:value) { false }

      it { is_expected.to eq 0.0 }
    end

    context 'with nil' do
      let(:value) { nil }

      it { is_expected.to eq 0.0 }
    end
  end

  describe '#in' do
    subject(:result) { type.in value }

    context 'with an integer' do
      let(:value) { 42 }

      it 'converts the integer to float' do
        expect(result).to eq 42.0
      end
    end

    context 'with a float' do
      let(:value) { 4.8 }

      it 'returns that float' do
        expect(result).to eq 4.8
      end
    end

    context 'with a string' do
      let(:value) { 'hello' }

      it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
    end

    context 'with the empty string' do
      let(:value) { '' }

      it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
    end

    context 'with nested types' do
      let(:value) { [{foo: :bar}] }

      it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
    end

    context 'with true' do
      let(:value) { true }

      it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
    end

    context 'with false' do
      let(:value) { false }

      it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
    end

    context 'with nil' do
      let(:value) { nil }

      it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
    end
  end
end
