# frozen_string_literal: true

require 'spec_helper'

describe 'Role: Show', type: :request do
  let(:api) { restify_with_headers(account_service_url).get.value! }
  let!(:role) { create(:'account_service/role') }

  context 'by id' do
    subject(:resource) { api.rel(:role).get({id: role.id}).value! }

    it 'responds successful' do
      puts "Requesting role by ID: #{account_service_url}"
      expect(resource).to respond_with :ok
    end

    it 'returns the requested role' do
      expect(resource).to eq json(role)
    end
  end

  context 'by name' do
    subject(:resource) { api.rel(:role).get({id: role.name}).value! }

    let!(:role) { create(:'account_service/role', name: 'account.admins') }

    it 'responds successful' do
      expect(resource).to respond_with :ok
    end

    it 'returns the requested role' do
      expect(resource).to eq json(role)
    end
  end
end
