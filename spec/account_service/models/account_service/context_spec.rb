# frozen_string_literal: true

require 'spec_helper'

describe AccountService::Context, type: :model do
  let(:context) { create(:'account_service/context') }

  describe '.resolve' do
    subject(:resolved) { AccountService::Context.resolve param }

    context 'with UUID string' do
      let(:param) { context.id.to_s }

      it { expect(resolved.id).to eq context.id }
    end

    context "with 'root' name" do
      let(:param) { 'root' }

      it { expect(resolved.id).to eq AccountService::Context.root.id }
    end
  end

  describe '#ascent' do
    let!(:context0) { create(:'account_service/context') }
    let!(:context1) { create(:'account_service/context', parent: context0) }
    let!(:context2) { create(:'account_service/context', parent: context1) }

    before do
      create(:'account_service/context')
      create(:'account_service/context', parent: context1)
    end

    context 'without block' do
      subject(:ascent) { context2.ascent }

      it { expect(ascent.to_a).to eq [context2, context1, context0, AccountService::Context.root] }
    end

    context 'with block' do
      it 'yields itself and all parent contects' do
        expect {|b| context2.ascent(&b) }.to \
          yield_successive_args(context2, context1, context0, AccountService::Context.root)
      end
    end
  end

  describe '#ancestors' do
    let!(:context0) { create(:'account_service/context', reference_uri: 'urn:0') }
    let!(:context1) { create(:'account_service/context', parent: context0, reference_uri: 'urn:1') }
    let!(:context2) { create(:'account_service/context', parent: context1, reference_uri: 'urn:2') }

    before do
      create(:'account_service/context')
      create(:'account_service/context', parent: context1)
    end

    context 'without block' do
      subject(:ancestors) { context2.ancestors }

      it { expect(ancestors.to_a).to eq [context1, context0, AccountService::Context.root] }
    end

    context 'with block' do
      it 'yields all parent contexts' do
        expect {|b| context2.ancestors(&b) }.to \
          yield_successive_args(context1, context0, AccountService::Context.root)
      end
    end
  end
end
