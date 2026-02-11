# frozen_string_literal: true

require 'spec_helper'

describe 'Group: Update', type: :request do
  subject(:resource) { api.rel(:group).patch(data, params: {id: data[:name]}).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:data) { {name: 'xikolo.group', description: 'Just for testing.'} }

  before do
    create(:'account_service/group', name: 'xikolo.group', description: 'Existing group.')
  end

  it 'responds with :ok' do
    expect(resource).to respond_with :ok
  end

  it 'has location to updated resource' do
    expect(resource.follow).to eq account_service.group_url AccountService::Group.last
  end

  it 'does not create new database record' do
    expect { resource }.not_to change(AccountService::Group, :count)
  end

  it 'updates database record' do
    resource

    AccountService::Group.last.reload.tap do |group|
      expect(group.name).to eq 'xikolo.group'
      expect(group.description).to eq 'Just for testing.'
    end
  end

  it 'returns updated resource' do
    expect(resource).to eq json(AccountService::Group.last)
  end

  context 'w/ non-existent resource' do
    let(:data) { {name: 'xikolo.othergroup'} }

    it 'responds with :not_found' do
      expect { resource }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end
  end

  context 'using PUT method w/ non-existent resource' do
    subject(:resource) { api.rel(:group).put(data, params: {id: data[:name]}).value! }

    let(:data) { {name: 'xikolo.othergroup', description: 'Just for testing.'} }

    it 'adds database record' do
      expect { resource }.to change(AccountService::Group, :count).by(1)
    end

    it 'responds with :created' do
      expect(resource).to respond_with :created
    end
  end
end
