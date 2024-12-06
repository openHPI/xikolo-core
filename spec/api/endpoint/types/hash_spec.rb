# frozen_string_literal: true

require 'spec_helper'

describe 'Types: Hash' do
  let(:hash) { Xikolo::Endpoint::Types.make(:hash) }
  let(:hash_of_primitives) { Xikolo::Endpoint::Types.make(:hash, of: {foo: :string, bar: :integer}) }
  let(:hash_of_arrays) do
    Xikolo::Endpoint::Types.make(
      :hash, of: {
        foo: Xikolo::Endpoint::Types.make(
          :array, of: :string
        ),
        bar: Xikolo::Endpoint::Types.make(
          :array, of: :integer
        ),
      }
    )
  end

  describe '#out' do
    context 'hash of anything' do
      subject(:result) { hash.out value }

      context 'hash with valid keys' do
        let(:value) { {foo: 'foo', bar: 1} }

        it 'uses the input hash and converts the keys to strings' do
          expect(result).to eq('foo' => 'foo', 'bar' => 1)
        end
      end

      context 'with an integer' do
        let(:value) { 1 }

        it { is_expected.to eq({}) }
      end

      context 'with nil' do
        let(:value) { nil }

        it { is_expected.to eq({}) }
      end
    end

    context 'hash of primitives' do
      subject(:result) { hash_of_primitives.out value }

      context 'with valid values' do
        let(:value) { {foo: 'foo', bar: 1} }

        it 'uses the values and converts keys to strings' do
          expect(result).to eq('foo' => 'foo', 'bar' => 1)
        end
      end

      context 'with incompatible values' do
        let(:value) { {foo: 1, bar: 'bar'} }

        it 'uses the valid values and converts the incompatible ones' do
          expect(result).to eq('foo' => '1', 'bar' => 0)
        end
      end

      context 'with missing keys' do
        let(:value) { {} }

        it 'uses default values for the missing keys' do
          expect(result).to eq('foo' => nil, 'bar' => 0)
        end
      end

      context 'with nil' do
        let(:value) { nil }

        it 'returns a hash with default values' do
          expect(result).to eq('foo' => nil, 'bar' => 0)
        end
      end

      context 'with an array' do
        let(:value) { ['foo'] }

        it 'returns a hash with default values' do
          expect(result).to eq('foo' => nil, 'bar' => 0)
        end
      end
    end

    context 'hash of arrays' do
      subject(:result) { hash_of_arrays.out value }

      context 'with valid values' do
        let(:value) { {foo: %w[foo bar], bar: [1, 2]} }

        it 'uses that hash, converting keys to strings' do
          expect(result).to eq('foo' => %w[foo bar], 'bar' => [1, 2])
        end
      end

      context 'with incompatible values' do
        let(:value) { {foo: 1, bar: 'bar'} }

        it 'returns empty arrays as values' do
          expect(result).to eq('foo' => [], 'bar' => [])
        end
      end

      context 'with incomplete values' do
        let(:value) { {foo: %w[foo bar]} }

        it 'returns an empty array for missing keys' do
          expect(result).to eq('foo' => %w[foo bar], 'bar' => [])
        end
      end

      context 'with nil' do
        let(:value) { nil }

        it 'returns a hash with empty arrays for each key' do
          expect(result).to eq('foo' => [], 'bar' => [])
        end
      end

      context 'with an array' do
        let(:value) { ['foo'] }

        it 'returns a hash with empty arrays for each key' do
          expect(result).to eq('foo' => [], 'bar' => [])
        end
      end
    end
  end

  describe '#in' do
    context 'hash of anything' do
      subject(:result) { hash.in value }

      context 'with valid structure' do
        let(:value) { {'foo' => 'foo', 'bar' => 1} }

        it 'uses the input hash' do
          expect(result).to eq('foo' => 'foo', 'bar' => 1)
        end
      end

      context 'with incompatible values' do
        let(:value) { 1 }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with nil' do
        let(:value) { nil }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end
    end

    context 'hash of primitives' do
      subject(:result) { hash_of_primitives.in value }

      context 'with valid structure and values' do
        let(:value) { {'foo' => 'foo', 'bar' => 1} }

        it 'uses the input hash' do
          expect(result).to eq('foo' => 'foo', 'bar' => 1)
        end
      end

      context 'with invalid values' do
        let(:value) { {'foo' => 1, 'bar' => 'bar'} }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with incomplete values' do
        let(:value) { {'foo' => 'foo'} }

        it 'returns a hash with only the given values' do
          expect(result).to eq('foo' => 'foo')
        end
      end

      context 'with an integer' do
        let(:value) { 1 }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with nil' do
        let(:value) { nil }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with as array' do
        let(:value) { [] }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end
    end

    context 'hash of arrays' do
      subject(:result) { hash_of_arrays.in value }

      context 'with valid values' do
        let(:value) { {'foo' => %w[foo bar], 'bar' => [1, 2]} }

        it 'uses the input hash' do
          expect(result).to eq('foo' => %w[foo bar], 'bar' => [1, 2])
        end
      end

      context 'with invalid values' do
        let(:value) { {'foo' => %w[foo bar], 'bar' => 'bar'} }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with incomplete values' do
        let(:value) { {'foo' => %w[foo bar]} }

        it 'returns a hash with only the given values' do
          expect(result).to eq('foo' => %w[foo bar])
        end
      end

      context 'with an integer' do
        let(:value) { 1 }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with nil' do
        let(:value) { nil }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end

      context 'with as array' do
        let(:value) { [] }

        it { expect { result }.to raise_error(Xikolo::Error::InvalidValue) }
      end
    end
  end
end
