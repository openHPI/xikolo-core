# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::Endpoint::EntityDefinition do
  subject(:entity) do
    described_class.new(type, attributes, relationships, links, **opts)
  end

  let(:type) { 'foo' }
  let(:attributes) do
    [
      Xikolo::Endpoint::EntityAttribute.new('name', Xikolo::Endpoint::Types::String.new),
      Xikolo::Endpoint::EntityAttribute.new('longdesc', Xikolo::Endpoint::Types::String.new).tap do |attr|
        attr.member_only = true
      end,
    ]
  end
  let(:relationships) { {} }
  let(:links) { {} }
  let(:opts) { {} }
  let(:resource) do
    {
      'id' => '123',
      'name' => 'foo',
      'longdesc' => 'long text',
    }
  end

  describe '#rel?' do
    subject { entity.rel? rel_name }

    let(:rel_name) { 'my_relationship' }

    context 'when relationship does not exist' do
      it { is_expected.to be false }
    end

    context 'when relationship exists' do
      let(:relationships) do
        {
          rel_name => Xikolo::Endpoint::Relationships::Relationship.new(rel_name),
        }
      end

      it { is_expected.to be true }
    end
  end

  describe '#rel' do
    subject(:result) { entity.rel rel_name }

    let(:rel_name) { 'my_relationship' }
    let(:rel) { Xikolo::Endpoint::Relationships::Relationship.new(rel_name) }

    context 'when relationship does not exist' do
      it { expect { result }.to raise_error KeyError }
    end

    context 'when relationship exists' do
      let(:relationships) { {rel_name => rel} }

      it 'returns the relationship object' do
        expect(result).to be rel
      end
    end
  end

  describe '#from_member' do
    subject(:result) { entity.from_member resource }

    it { expect(result.type).to eq 'foo' }
    it { expect(result.id).to eq '123' }
    it { expect(result.attributes).to have_key 'name' }

    it 'includes the member-only attributes' do
      expect(result.attributes).to have_key 'longdesc'
    end

    context 'with additional attributes' do
      let(:resource) do
        super().merge(
          'some' => 'value',
          'other' => 'value'
        )
      end

      it 'only includes the declared attributes' do
        expect(result.attributes.size).to eq 2
      end
    end

    context 'with a link' do
      let(:links) do
        {
          'res' => Xikolo::Endpoint::EntityLink.new('foo', lambda {|resource|
            "/resources/#{resource['slug']}"
          }),
        }
      end

      let(:resource) do
        {'slug' => 'some-resource'}
      end

      it 'includes the link' do
        expect(result.links).to have_key 'res'
      end

      it 'has run the generator' do
        expect(result.links['res']).to eq '/resources/some-resource'
      end
    end

    context 'with a custom ID builder' do
      let(:opts) do
        {id_builder: proc {|resource| "prefix_#{resource['id']}" }}
      end

      it 'transforms the ID accordingly' do
        expect(result.id).to eq 'prefix_123'
      end
    end
  end

  describe '#from_collection' do
    subject(:result) { entity.from_collection [resource] }

    it { is_expected.to be_an Array }
    it { expect(result.first.attributes).to have_key 'name' }

    it 'does not include member-only attributes' do
      expect(result.first.attributes).not_to have_key 'longdesc'
    end
  end

  describe '#from_json_api' do
    subject(:result) { entity.from_json_api json_hash }

    context 'with a member resource' do
      let(:json_hash) do
        {
          'data' => {
            'type' => 'foo',
            'id' => '123',
            'attributes' => {
              'name' => 'foo',
              'longdesc' => 'long text',
            },
          },
        }
      end

      it { is_expected.to be_a Xikolo::JSONAPI::Entity }
    end

    context 'with a collection resource' do
      let(:json_hash) do
        {
          'data' => [
            {
              'type' => 'foo',
              'id' => '123',
              'attributes' => {
                'name' => 'foo',
                'longdesc' => 'long text',
              },
            },
            {
              'type' => 'foo',
              'id' => '456',
              'attributes' => {
                'name' => 'bar',
                'longdesc' => 'another long text',
              },
            },
          ],
        }
      end

      it { is_expected.to be_an Array }
    end

    context 'with a foreign resource' do
      let(:json_hash) do
        {
          'data' => {
            'type' => 'wrongtype',
            'id' => '123',
            'attributes' => {
              'name' => 'foo',
              'longdesc' => 'long text',
            },
          },
        }
      end

      it { expect { result }.to raise_error Exception }
    end
  end
end
