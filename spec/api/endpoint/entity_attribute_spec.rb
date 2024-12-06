# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::Endpoint::EntityAttribute do
  subject { attribute }

  let(:attribute) { described_class.new(name, type, description, opts) }
  let(:name) { 'foo' }
  let(:type) { Xikolo::Endpoint::Types::String.new }
  let(:description) { '' }
  let(:opts) { {} }

  let(:invertible_mapping) { {'type1' => 'type_1', 'type2' => 'type_2'} }
  let(:non_invertible_mapping) { {'type1' => 'foo', 'type2' => 'foo'} }

  describe '#read' do
    subject { super().read(resource) }

    context 'existing attribute' do
      let(:resource) { {'foo' => 'bar'} }

      it { is_expected.to eq('foo' => 'bar') }
    end

    context 'aliased attribute' do
      let(:resource) { {'baz' => 'bar'} }
      let(:opts) { super().merge(alias: 'baz') }

      it { is_expected.to eq('foo' => 'bar') }
    end

    context 'attribute with transformer' do
      let(:resource) { {'foo' => 'bar'} }
      let(:opts) { super().merge(read_transformer: proc {|res| res['foo'].to_s * 2 }) }

      it { is_expected.to eq('foo' => 'barbar') }
    end

    context 'attribute with mapping' do
      let(:resource) { {'foo' => 'type1'} }
      let(:opts) { super().merge(map: invertible_mapping) }

      it { is_expected.to eq('foo' => 'type_1') }
    end

    context 'aliased attribute with mapping' do
      let(:resource) { {'type' => 'type1'} }
      let(:opts) { super().merge(alias: 'type', map: invertible_mapping) }

      it { is_expected.to eq('foo' => 'type_1') }
    end

    context 'missing attribute' do
      let(:resource) { {} }

      it { is_expected.to eq('foo' => nil) }
    end
  end

  describe '#can_write?' do
    subject { super().can_write? }

    context 'default' do
      it { is_expected.to be_falsy }
    end

    context 'aliased attribute' do
      let(:opts) { super().merge(alias: 'baz') }

      it { is_expected.to be_falsy }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to be_truthy }
      end
    end

    context 'attribute with transformer' do
      let(:opts) { super().merge(read_transformer: proc {|res| res['foo'].to_s * 2 }) }

      it { is_expected.to be_falsy }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to be_truthy }
      end
    end

    context 'attribute with invertible mapping' do
      let(:opts) { super().merge(map: invertible_mapping) }

      it { is_expected.to be_falsy }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to be_truthy }
      end
    end

    context 'attribute with non-invertible mapping' do
      let(:opts) { super().merge(map: non_invertible_mapping) }

      it { is_expected.to be_falsy }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to be_falsy }
      end
    end

    context 'attribute with write transformer' do
      let(:opts) do
        super().merge(
          read_transformer: proc {|res| res['foo'].upcase },
          write_transformer: proc {|val| val.downcase }
        )
      end

      it { is_expected.to be_falsy }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#write' do
    subject { super().write(params) }

    context 'existing attribute' do
      let(:params) { {'foo' => 'bar'} }

      it { is_expected.to eq({}) }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to eq('foo' => 'bar') }
      end
    end

    context 'aliased attribute' do
      let(:params) { {'foo' => 'bar'} }
      let(:opts) { super().merge(alias: 'baz') }

      it { is_expected.to eq({}) }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to eq('baz' => 'bar') }
      end
    end

    context 'missing attribute' do
      let(:params) { {} }

      it { is_expected.to eq({}) }
    end

    context 'with transformer' do
      let(:params) { {'foo' => 'bar'} }
      let(:opts) { super().merge(read_transformer: proc { 'xxx' }) }

      it { is_expected.to eq({}) }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to eq('foo' => 'bar') }
      end
    end

    context 'with write transformer' do
      let(:params) { {'foo' => 'BAR'} }
      let(:opts) do
        super().merge(
          read_transformer: proc {|res| res['foo'].upcase },
          write_transformer: proc {|val| val.downcase }
        )
      end

      it { is_expected.to eq({}) }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to eq('foo' => 'bar') }
      end
    end

    context 'with write transformer that returns a hash' do
      let(:params) { {'foo' => 'foo bar'} }
      let(:opts) do
        super().merge(
          read_transformer: proc {|res| "#{res['first_name']} #{res['last_name']}" },
          write_transformer: proc {|val|
                               {
                                 'first_name' => val.split.first,
                                         'last_name' => val.split.second,
                               }
                             }
        )
      end

      it { is_expected.to eq({}) }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to eq('first_name' => 'foo', 'last_name' => 'bar') }
      end
    end

    context 'with an invertible mapping' do
      let(:params) { {'foo' => 'type_2'} }
      let(:opts) { super().merge(map: invertible_mapping) }

      it { is_expected.to eq({}) }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to eq('foo' => 'type2') }
      end
    end

    context 'with alias and invertible mapping' do
      let(:params) { {'foo' => 'type_2'} }
      let(:opts) do
        super().merge(
          map: invertible_mapping,
          alias: 'type'
        )
      end

      it { is_expected.to eq({}) }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to eq('type' => 'type2') }
      end
    end

    context 'with a non-invertible mapping' do
      let(:params) { {'foo' => 'type_2'} }
      let(:opts) { super().merge(map: non_invertible_mapping) }

      it { is_expected.to eq({}) }

      context 'when writable' do
        before { attribute.writable = true }

        it { is_expected.to eq({}) }
      end
    end
  end
end
