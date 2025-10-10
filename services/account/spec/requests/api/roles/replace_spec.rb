# frozen_string_literal: true

require 'spec_helper'

describe 'Role: Update', type: :request do
  subject(:resource) { api.rel(:role).put(data, params: {id: data[:name]}).value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:data) do
    {
      name: 'account.admins',
      permissions: ['account.users.create', 'account.users.update'],
    }
  end

  it 'responds with 201 created' do
    expect(resource).to respond_with :created
  end

  it 'creates new record' do
    expect { resource }.to change(Role, :count).from(0).to(1)

    Role.last.tap do |role|
      expect(role.name).to eq 'account.admins'
      expect(role.permissions).to contain_exactly('account.users.create', 'account.users.update')
    end
  end

  it 'has location to newly created resource' do
    expect(resource.follow).to eq account_service.role_url Role.last
  end

  it 'returns created resource' do
    expect(resource).to eq json(Role.last)
  end
end
