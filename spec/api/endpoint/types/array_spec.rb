# frozen_string_literal: true

require 'spec_helper'

describe 'Types: Array' do
  let(:array_of_strings) { Xikolo::Endpoint::Types.make(:array, of: :string) }
  let(:array_of_hashes) do
    Xikolo::Endpoint::Types.make(
      :array, of: Xikolo::Endpoint::Types.make(
        :hash, of: {
          foo: :string,
          bar: :string,
        }
      )
    )
  end

  describe '#out' do
    context 'array of strings' do
      subject(:result) { array_of_strings.out value }

      context 'with strings' do
        let(:value) { %w[foo bar] }

        it 'returns that array' do
          expect(result).to eq %w[foo bar]
        end
      end

      context 'with integers' do
        let(:value) { [1, 2] }

        it 'converts the integers to strings' do
          expect(result).to eq %w[1 2]
        end
      end

      context 'with integers and strings' do
        let(:value) { [1, 'foo', 2, 'bar'] }

        it 'converts all integers to strings' do
          expect(result).to eq %w[1 foo 2 bar]
        end
      end

      context 'with nil' do
        let(:value) { nil }

        it { is_expected.to eq [] }
      end

      context 'with a hash' do
        let(:value) { {foo: :bar} }

        it { is_expected.to eq [] }
      end
    end

    context 'array of hashes' do
      subject(:result) { array_of_hashes.out value }

      context 'with an array of valid hashes' do
        let(:value) { [{foo: 'foo', bar: 'bar'}, {foo: 'hello', bar: 'world'}] }

        it 'converts the hashes to have string keys and the given values' do
          expect(result).to eq [{'foo' => 'foo', 'bar' => 'bar'}, {'foo' => 'hello', 'bar' => 'world'}]
        end
      end

      context 'with an array with an invalid hash' do
        let(:value) { [{}] }

        it 'converts that hash to have nil values for the required keys' do
          expect(result).to eq [{'foo' => nil, 'bar' => nil}]
        end
      end

      context 'with nil' do
        let(:value) { nil }

        it { is_expected.to eq [] }
      end

      context 'with a string' do
        let(:value) { 'foobar' }

        it { is_expected.to eq [] }
      end
    end
  end

  describe '#in' do
    context 'array of strings' do
      subject(:result) { array_of_strings.in value }

      context 'with strings' do
        let(:value) { %w[foo bar] }

        it 'uses the input array' do
          expect(result).to eq %w[foo bar]
        end
      end

      context 'with an integer array' do
        let(:value) { [1] }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with a plain integer' do
        let(:value) { 1 }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with a plain string' do
        let(:value) { 'foo' }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with nil' do
        let(:value) { nil }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with a hash' do
        let(:value) { {foo: :bar} }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end
    end

    context 'array of hashes' do
      subject(:result) { array_of_hashes.in value }

      context 'with an array of valid hashes' do
        let(:value) { [{foo: 'foo', bar: 'bar'}, {foo: 'hello', bar: 'world'}] }

        it 'converts the hashes to have string keys and the given values' do
          expect(result).to eq [{'foo' => 'foo', 'bar' => 'bar'}, {'foo' => 'hello', 'bar' => 'world'}]
        end
      end

      context 'with an array with an invalid hash' do
        let(:value) { [{}] }

        it 'converts that hash to have nil values for the required keys' do
          expect(result).to eq [{}]
        end
      end

      context 'with nil' do
        let(:value) { nil }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with a string' do
        let(:value) { 'foobar' }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end
    end
  end
end
