# frozen_string_literal: true

require 'spec_helper'

describe 'Role: Update', type: :request do
  subject(:resource) { api.rel(:role).patch(data, params: {id: data[:name]}).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:data) do
    {
      name: 'account.admins',
      permissions: ['account.users.create', 'account.users.update'],
    }
  end

  let!(:role) { create(:'account_service/role', name: 'account.admins', permissions: ['account.users.index']) }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'has location to updated resource' do
    expect(resource.follow).to eq account_service.role_url AccountService::Role.last
  end

  it 'does not create new database record' do
    expect { resource }.not_to change(AccountService::Role, :count)
  end

  it 'updates database record' do
    resource

    role.reload.tap do |role|
      expect(role.name).to eq 'account.admins'
      expect(role.permissions).to contain_exactly('account.users.create', 'account.users.update')
    end
  end

  it 'returns updated resource' do
    expect(resource).to eq json(AccountService::Role.last)
  end

  context 'w/ non-existent resource' do
    let(:data) { {name: 'account.roots'} }

    it 'responds with 404 Not Found' do
      expect { resource }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end
  end

  context 'using PUT method w/ non-existent resource' do
    subject(:resource) { api.rel(:role).put(data, params: {id: data[:name]}).value! }

    let(:data) { {name: 'xikolo.helpdesk', permissions: []} }

    it 'adds database record' do
      expect { resource }.to change(AccountService::Role, :count).by(1)
    end

    it 'responds with 201 Created' do
      expect(resource).to respond_with :created
    end
  end
end
