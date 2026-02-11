# frozen_string_literal: true

require 'spec_helper'

describe 'List user features', type: :request do
  subject(:resource) { base.rel(:features).get.value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:base) { api.rel(:user).get({id: user}).value! }
  let(:user) { create(:'account_service/user') }

  let(:groups) { create_list(:'account_service/group', 5) }

  let(:target_features) do
    AccountService::Feature.where(owner: user, context: AccountService::Context.root) +
      AccountService::Feature.where(owner: [groups[2], groups[3]], context: AccountService::Context.root)
  end

  let(:target_features_json) { AccountService::FeaturesDecorator.new(target_features).as_json }

  before do
    AccountService::Feature.destroy_all
    groups.map {|group| create_list(:'account_service/feature', 4, owner: group) }
    create_list(:'account_service/feature', 2, owner: user)

    user.memberships.create! group: groups[2]
    user.memberships.create! group: groups[3]
  end

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with features' do
    expect(resource).to eq target_features_json
  end

  context '?context' do
    subject(:resource) { base.rel(:features).get({context:}).value! }

    let(:context) { create(:'account_service/context') }

    it 'responds with features' do
      expect(resource).to eq target_features_json
    end

    context 'with user context features' do
      let!(:context_feature) { create(:'account_service/feature', owner: user, context:) }
      let(:target_features) { super() + [context_feature] }

      it 'responds with features' do
        expect(resource).to eq target_features_json
      end
    end
  end
end
