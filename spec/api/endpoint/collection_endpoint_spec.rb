# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::Endpoint::CollectionEndpoint do
  subject(:endpoint) { Class.new(described_class) }

  describe '#entity_definition' do
    subject(:entity_definition) { endpoint.entity_definition }

    before { endpoint.entity(&entity_block) }

    let(:relationship) { Class.new }
    let(:entity_block) do
      rel_klass = relationship
      lambda {
        type 'comment'
        attribute('text') do
          type :string
        end
        has_one('article', rel_klass) { foreign_key 'article_id' }
      }
    end

    describe '#type' do
      subject { entity_definition.type }

      it { is_expected.to eq 'comment' }
    end

    describe '#attributes' do
      subject { entity_definition.attributes }

      it { is_expected.to be_a Array }
    end

    describe '#relationships' do
      subject(:relationships) { entity_definition.relationships }

      it { is_expected.to be_a Array }

      describe 'the article relationship' do
        subject(:first) { relationships.first }

        it { expect(first.name).to eq 'article' }
        it { is_expected.to be_a Xikolo::Endpoint::Relationships::HasOneRelationship }
      end
    end
  end

  describe '#pagination?' do
    subject { super().pagination? }

    context 'by default' do
      it { is_expected.to be false }
    end

    context 'if enabled' do
      before { endpoint.paginate! }

      it { is_expected.to be true }
    end
  end

  describe 'pagination' do
    subject { super().pagination }

    context 'by default' do
      it { is_expected.to be_nil }
    end

    context 'if enabled' do
      before { endpoint.paginate! }

      it { is_expected.to be_a Xikolo::Endpoint::Pagination }
    end
  end
end
