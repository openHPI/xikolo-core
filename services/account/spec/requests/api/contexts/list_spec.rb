# frozen_string_literal: true

require 'spec_helper'

describe 'Context: List', type: :request do
  subject(:resource) { api.rel(:contexts).get(params).value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:params) { {} }

  before { AccountService::Context.root }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'lists the available contexts' do
    expect(resource).to match_array json([AccountService::Context.root])
  end

  context '?ancestors' do
    let!(:context1) { create(:'account_service/context') }
    let!(:context2) { create(:'account_service/context', parent: context1) }
    let!(:context3) { create(:'account_service/context', parent: context2) }
    let!(:context4) { create(:'account_service/context', parent: context3) }

    context '=root' do
      let(:params) { {ancestors: 'root'} }

      it { is_expected.to respond_with :ok }
      it { is_expected.to eq json([]) }
    end

    context '=<UUID:root>' do
      let(:params) { {ancestors: AccountService::Context.root.id} }

      it { is_expected.to respond_with :ok }
      it { is_expected.to eq json([]) }
    end

    context '=context1' do
      let(:params) { {ancestors: context1} }

      it { is_expected.to respond_with :ok }
      # Use `eq` instead of `match_array` to ensure ordering
      it { expect(resource.as_json).to eq json([AccountService::Context.root]) }
    end

    context '=context2' do
      let(:params) { {ancestors: context2} }

      it { is_expected.to respond_with :ok }
      # Use `eq` instead of `match_array` to ensure ordering
      it { expect(resource.as_json).to eq json([context1, AccountService::Context.root]) }
    end

    context '=context3' do
      let(:params) { {ancestors: context3} }

      it { is_expected.to respond_with :ok }
      # Use `eq` instead of `match_array` to ensure ordering
      it { expect(resource.as_json).to eq json([context2, context1, AccountService::Context.root]) }
    end

    context '=context4' do
      let(:params) { {ancestors: context4} }

      it { is_expected.to respond_with :ok }
      # Use `eq` instead of `match_array` to ensure ordering
      it { expect(resource.as_json).to eq json([context3, context2, context1, AccountService::Context.root]) }
    end
  end

  context '?ascent' do
    let!(:context1) { create(:'account_service/context') }
    let!(:context2) { create(:'account_service/context', parent: context1) }
    let!(:context3) { create(:'account_service/context', parent: context2) }
    let!(:context4) { create(:'account_service/context', parent: context3) }

    context '=root' do
      let(:params) { {ascent: 'root'} }

      it { is_expected.to respond_with :ok }
      it { is_expected.to eq json([AccountService::Context.root]) }
    end

    context '=<UUID:root>' do
      let(:params) { {ascent: AccountService::Context.root.id} }

      it { is_expected.to respond_with :ok }
      it { is_expected.to eq json([AccountService::Context.root]) }
    end

    context '=context1' do
      let(:params) { {ascent: context1} }

      it { is_expected.to respond_with :ok }
      # Use `eq` instead of `match_array` to ensure ordering
      it { expect(resource.as_json).to eq json([context1, AccountService::Context.root]) }
    end

    context '=context2' do
      let(:params) { {ascent: context2} }

      it { is_expected.to respond_with :ok }
      # Use `eq` instead of `match_array` to ensure ordering
      it { expect(resource.as_json).to eq json([context2, context1, AccountService::Context.root]) }
    end

    context '=context3' do
      let(:params) { {ascent: context3} }

      it { is_expected.to respond_with :ok }
      # Use `eq` instead of `match_array` to ensure ordering
      it { expect(resource.as_json).to eq json([context3, context2, context1, AccountService::Context.root]) }
    end

    context '=context4' do
      let(:params) { {ascent: context4} }

      it { is_expected.to respond_with :ok }
      # Use `eq` instead of `match_array` to ensure ordering
      it { expect(resource.as_json).to eq json([context4, context3, context2, context1, AccountService::Context.root]) }
    end
  end
end
