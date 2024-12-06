# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::JSONAPI::Entity do
  subject(:entity) do
    described_class.new(
      entity_definition,
      'abc',
      {'title' => 'foobar'},
      relationships,
      links
    )
  end

  let(:entity_definition) { Xikolo::Endpoint::EntityDefinition.new 'course' }

  let(:relationships) { {} }
  let(:links) do
    {
      'self' => '/some/link',
      'missing_link' => nil,
    }
  end

  # :eql? and :hash - Used by Ruby's Set class for comparison and inclusion checks
  describe '#eql?' do
    subject { entity.eql? other_entity }

    context 'self' do
      let(:other_entity) { entity }

      it { is_expected.to be true }
    end

    context 'a duplicate' do
      let(:other_entity) { entity.dup }

      it { is_expected.to be true }
    end

    context 'same type, different ID' do
      let(:other_entity) { described_class.new entity_definition, 'def', {} }

      it { is_expected.to be false }
    end

    context 'different type' do
      let(:other_entity) { described_class.new entity_definition, '123', {} }

      it { is_expected.to be false }
    end
  end

  describe '#hash' do
    subject { entity.hash }

    it { is_expected.to be_a Integer }
  end

  describe '#identifier' do
    subject(:identifier) { entity.identifier }

    it { is_expected.to be_a Hash }

    it {
      expect(identifier).to eq(
        'type' => 'course',
        'id' => 'abc'
      )
    }
  end

  describe '#serialize' do
    subject(:serialize) { entity.serialize context }

    let(:context) { double }

    it { is_expected.to be_a Hash }

    it {
      expect(serialize).to eq(
        'type' => 'course',
        'id' => 'abc',
        'attributes' => {
          'title' => 'foobar',
        },
        'links' => {
          'self' => '/some/link',
        }
      )
    }
  end

  describe '#to_resource' do
    subject { entity.to_resource }

    it { is_expected.to be_a Hash }
    it { is_expected.to be_empty }

    context 'with allowed attributes' do
      let(:entity_definition) do
        Xikolo::Endpoint::EntityDefinition.new(
          'course',
          [
            Xikolo::Endpoint::EntityAttribute.new('title', Xikolo::Endpoint::Types::String.new).tap do |attr|
              attr.writable = true
            end,
          ]
        )
      end

      it { is_expected.to eq('title' => 'foobar') }
    end
  end

  describe '#related_resources_for' do
    subject(:related_resources_for) do
      entity.related_resources_for relationship_name, context
    end

    let(:context) { double }

    context 'for a non-existing relationship name' do
      let(:relationship_name) { 'nonexistant' }

      it { expect { related_resources_for }.to raise_error KeyError }
    end

    context 'for an existing relationship' do
      let(:relationship_name) { 'children' }
      let(:relationships) { {'children' => double} }

      let(:related_objects) { [] }

      before do
        allow(relationships['children']).to receive(:related).and_return(related_objects)
      end

      it 'sideloads the related resources via the relationship object' do
        related_resources_for
        expect(relationships['children']).to have_received(:related).with(context)
      end

      it 'returns the sideloaded resources' do
        expect(related_resources_for).to eq related_objects
      end
    end
  end
end
