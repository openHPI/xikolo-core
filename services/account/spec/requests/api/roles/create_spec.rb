# frozen_string_literal: true

require 'spec_helper'

describe 'Role: Create', type: :request do
  subject(:resource) { api.rel(:roles).post(data).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:data) { {name: 'account.admins', permissions: ['account.users.create', 'account.users.update']} }

  it 'responds with a created resource' do
    expect(resource).to respond_with :created
  end

  it 'responds with a follow location to created resource' do
    expect(resource.follow.to_s).to eq role_url(Role.last)
  end

  it 'creates database record' do
    expect { resource }.to change(Role, :count).from(0).to(1)
  end

  it 'saves the provided data' do
    resource
    role = Role.last
    expect(role.name).to eq 'account.admins'
    expect(role.permissions).to contain_exactly('account.users.create', 'account.users.update')
  end

  it 'returns created role' do
    expect(resource).to eq json(Role.last)
  end

  context 'with invalid name' do
    let(:data) { super().merge name: 'abc' }

    it 'responds with 422 Unprocessable Entity' do
      expect { resource }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
      end
    end

    it 'does not create record' do
      expect do
        resource
      rescue StandardError
        nil
      end.not_to change(Role, :count)
    end
  end
end
