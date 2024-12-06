# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::JSONAPI::Document do
  subject(:document) { described_class.new context }

  let(:context) { instance_double(Xikolo::Middleware::RunContext) }

  describe '#include!' do
    subject(:included) { document.include!(*includes) }

    let(:includes) { [] }
    let(:data) { entity }

    let(:entity) { instance_double(Xikolo::JSONAPI::Entity) }

    before { document.data = data }

    it { is_expected.to be_empty }

    context 'with multiple relationships to include' do
      let(:includes) { %w[foo bar] }

      let(:related1) { double }
      let(:related2) { double }
      let(:related3) { double }

      before do
        allow(entity).to receive(:related_resources_for)
          .with('foo', context)
          .and_return Restify::Promise.fulfilled([related1])
        allow(entity).to receive(:related_resources_for)
          .with('bar', context)
          .and_return Restify::Promise.fulfilled([related2, related3])
      end

      it 'returns all related objects' do
        expect(included.size).to eq 3
      end

      context 'with duplicate related resources' do
        let(:related3) { related2 }

        it 'does not return any duplicates' do
          expect(included.size).to eq 2
        end
      end
    end

    context 'with multiple objects to load related objects from' do
      let(:data) { [entity, entity2] }
      let(:entity2) { instance_double(Xikolo::JSONAPI::Entity) }

      let(:includes) { 'foo' }

      let(:related1) { double }
      let(:related2) { double }
      let(:related3) { double }

      before do
        allow(entity).to receive(:related_resources_for)
          .with('foo', context)
          .and_return Restify::Promise.fulfilled([related1, related2])
        allow(entity2).to receive(:related_resources_for)
          .with('foo', context)
          .and_return Restify::Promise.fulfilled([related3])
      end

      it 'returns all related objects from all objects' do
        expect(included.size).to eq 3
      end
    end
  end
end
