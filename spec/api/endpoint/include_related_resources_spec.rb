# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::Endpoint::IncludeRelatedResources do
  subject(:loader) { described_class.new entity, document, include_string }

  let(:entity) { Xikolo::Endpoint::EntityDefinition.new }
  let(:include_string) { '' }

  let(:document) { instance_double(Xikolo::JSONAPI::Document) }

  describe '#with_includes' do
    subject(:with_includes) { loader.with_includes { nil } }

    let(:default_includes) { [] }
    let(:includables) { [] }

    context 'no allowed relationships' do
      context 'empty include string' do
        it 'includes no documents' do
          expect(document).to receive(:include!).with no_args
          with_includes
        end
      end

      context 'trying to include another relationship' do
        let(:include_string) { 'authors' }

        it do
          expect { with_includes }.to raise_error Xikolo::Error::BadRequest
        end
      end
    end

    context 'one allowed relationships' do
      let(:entity) do
        Xikolo::Endpoint::EntityDefinition::Factory.new.build do
          includable has_one('foo', Class.new)
        end
      end

      context 'empty include string' do
        it 'includes no documents' do
          expect(document).to receive(:include!).with no_args
          with_includes
        end
      end

      context 'trying to include another relationship' do
        let(:include_string) { 'authors' }

        it do
          expect { with_includes }.to raise_error Xikolo::Error::BadRequest
        end
      end

      context 'requesting to include the allowed relationship' do
        let(:include_string) { 'foo' }

        it 'loads the default relationship' do
          expect(document).to receive(:include!).with 'foo'
          with_includes
        end
      end

      context 'that is included by default' do
        before do
          allow(entity.rel('foo')).to receive(:include?).and_return(true)
        end

        context 'empty include string' do
          it 'loads the default relationship' do
            expect(document).to receive(:include!).with 'foo'
            with_includes
          end
        end

        context 'trying to include another relationship' do
          let(:include_string) { 'authors' }

          it do
            expect { with_includes }.to raise_error Xikolo::Error::BadRequest
          end
        end

        context 'requesting to include the allowed relationship' do
          let(:include_string) { 'foo' }

          it 'loads the requested relationship' do
            expect(document).to receive(:include!).with 'foo'
            with_includes
          end
        end
      end
    end

    context 'multiple allowed relationships' do
      let(:entity) do
        Xikolo::Endpoint::EntityDefinition::Factory.new.build do
          includable has_one('foo', Class.new)
          includable has_one('bar', Class.new)
          includable has_one('baz', Class.new)
        end
      end

      context 'empty include string' do
        it 'includes no documents' do
          expect(document).to receive(:include!).with no_args
          with_includes
        end
      end

      context 'trying to include another relationship' do
        let(:include_string) { 'authors' }

        it do
          expect { with_includes }.to raise_error Xikolo::Error::BadRequest
        end
      end

      context 'requesting to include one of the allowed relationship' do
        let(:include_string) { 'foo' }

        it 'loads the default relationship' do
          expect(document).to receive(:include!).with 'foo'
          with_includes
        end
      end

      context 'one of which is included by default' do
        before do
          allow(entity.rel('foo')).to receive(:include?).and_return(true)
        end

        context 'empty include string' do
          it 'loads the default relationship' do
            expect(document).to receive(:include!).with 'foo'
            with_includes
          end
        end

        context 'trying to include another relationship' do
          let(:include_string) { 'authors' }

          it do
            expect { with_includes }.to raise_error Xikolo::Error::BadRequest
          end
        end

        context 'requesting to include some of the allowed relationship' do
          let(:include_string) { 'bar,baz' }

          it 'only loads the requested relationships' do
            expect(document).to receive(:include!).with 'bar', 'baz'
            with_includes
          end
        end
      end
    end
  end
end
