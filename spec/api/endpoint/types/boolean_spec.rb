# frozen_string_literal: true

require 'spec_helper'

describe 'Types: Boolean' do
  subject(:type) { Xikolo::Endpoint::Types.make(:boolean) }

  describe '#out' do
    subject { type.out value }

    context 'with an integer' do
      let(:value) { 42 }

      it { is_expected.to be true }
    end

    context 'with zero' do
      let(:value) { 0 }

      it { is_expected.to be true }
    end

    context 'with a float' do
      let(:value) { 4.8 }

      it { is_expected.to be true }
    end

    context 'with a string' do
      let(:value) { 'hello' }

      it { is_expected.to be true }
    end

    context 'with the empty string' do
      let(:value) { '' }

      it { is_expected.to be true }
    end

    context 'with nested types' do
      let(:value) { [{foo: :bar}] }

      it { is_expected.to be true }
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

      it { is_expected.to be false }
    end
  end

  describe '#in' do
    subject(:result) { type.in value }

    context 'with an integer' do
      let(:value) { 42 }

      it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
    end

    context 'with zero' do
      let(:value) { 0 }

      it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
    end

    context 'with a float' do
      let(:value) { 4.8 }

      it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
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

      it { is_expected.to be true }
    end

    context 'with false' do
      let(:value) { false }

      it { is_expected.to be false }
    end

    context 'with nil' do
      let(:value) { nil }

      it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
    end
  end
end
