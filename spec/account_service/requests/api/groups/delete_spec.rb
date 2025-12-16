# frozen_string_literal: true

require 'spec_helper'

describe 'Groups: Deletion', type: :request do
  subject(:resource) { api.rel(:group).delete({id: group}).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:data) { {name: 'testowner.group_x'} }
  let!(:group) { create(:'account_service/group', data) }

  it 'responds with a OK resource' do
    expect(resource).to respond_with :ok
  end

  it 'deletes database record' do
    expect { resource }.to change(AccountService::Group, :count).from(1).to(0)
  end

  it 'returns deleted group' do
    expect(resource).to eq json(group)
  end

  context 'with memberships' do
    before do
      create_list(:'account_service/membership', 5, group:)
      create_list(:'account_service/membership', 5)
    end

    it 'deletes membership records' do
      expect { resource }.to change { AccountService::Membership.where(group:).count }.from(5).to(0)
    end

    it 'does not delete other memberships' do
      expect { resource }.to change(AccountService::Membership, :count).from(10).to(5)
    end
  end

  context 'with grants' do
    before do
      create_list(:'account_service/grant', 5, principal: group)
      create_list(:'account_service/grant', 5)
    end

    it 'deletes associated grants' do
      expect { resource }.to change {
        AccountService::Grant.where(principal: group).count
      }.from(5).to(0)
    end

    it 'does not delete other grants' do
      expect { resource }.to change(AccountService::Grant, :count).from(10).to(5)
    end
  end
end
