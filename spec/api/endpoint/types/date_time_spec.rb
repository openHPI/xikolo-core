# frozen_string_literal: true

require 'spec_helper'

describe 'Types: Date Time' do
  subject(:type) { Xikolo::Endpoint::Types.make(:datetime) }

  describe '#out' do
    subject(:result) { type.out value }

    context 'with a string in ISO 8601 format' do
      let(:value) { '2007-12-24T13:45:00.000+00:00' }

      it 'returns that string' do
        expect(result).to eq '2007-12-24T13:45:00.000+00:00'
      end
    end

    context 'with a string in another valid date format' do
      let(:value) { '2007-12-24 13:45:00' }

      it 'returns that date in ISO 8601 format, with three digits after the comma' do
        expect(result).to eq '2007-12-24T13:45:00.000+00:00'
      end
    end

    context 'with an integer' do
      let(:value) { 42 }

      it { is_expected.to be_nil }
    end

    context 'with a float' do
      let(:value) { 4.8 }

      it { is_expected.to be_nil }
    end

    context 'with a string' do
      let(:value) { 'hello' }

      it { is_expected.to be_nil }
    end

    context 'with the empty string' do
      let(:value) { '' }

      it { is_expected.to be_nil }
    end

    context 'with nested types' do
      let(:value) { [{foo: :bar}] }

      it { is_expected.to be_nil }
    end

    context 'with true' do
      let(:value) { true }

      it { is_expected.to be_nil }
    end

    context 'with false' do
      let(:value) { false }

      it { is_expected.to be_nil }
    end

    context 'with nil' do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#in' do
    subject(:result) { type.in value }

    context 'with a string in ISO 8601 format' do
      let(:value) { '2007-12-24T13:45:00.000+00:00' }

      it 'returns that string' do
        expect(result).to eq '2007-12-24T13:45:00.000+00:00'
      end
    end

    context 'with a string in another valid date format' do
      let(:value) { '2007-12-24 13:45:00' }

      it 'returns that date in ISO 8601 format, with three digits after the comma' do
        expect(result).to eq '2007-12-24T13:45:00.000+00:00'
      end
    end

    context 'with an integer' do
      let(:value) { 42 }

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

    context 'with a string containing a number' do
      let(:value) { '42' }

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

      it { is_expected.to be_nil }
    end
  end
end
