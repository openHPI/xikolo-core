# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::Endpoint::Relationships::HasManyRelationship do
  subject(:relationship) { described_class.new(name, other_endpoint, opts) }

  let(:name) { 'foo' }
  let(:other_endpoint) { Class.new(Xikolo::Endpoint::CollectionEndpoint) }
  let(:opts) { {} }

  describe 'creation' do
    context 'without a valid foreign key' do
      it 'raises an ArgumentError' do
        expect { relationship }.to raise_error(ArgumentError)
      end
    end

    context 'with a valid foreign key' do
      let(:opts) { {foreign_key_filter: 'existing', foreign_key_attr: 'id'} }

      it { is_expected.to be_a described_class }
    end
  end
end
