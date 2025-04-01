# frozen_string_literal: true

require 'spec_helper'

describe 'Group: Update', type: :request do
  subject(:resource) { api.rel(:group).patch(data, params: {id: data[:name]}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:data) { {name: 'xikolo.group', description: 'Just for testing.'} }

  before do
    create(:group, name: 'xikolo.group', description: 'Existing group.')
  end

  it 'responds with :ok' do
    expect(resource).to respond_with :ok
  end

  it 'has location to updated resource' do
    expect(resource.follow).to eq group_url Group.last
  end

  it 'does not create new database record' do
    expect { resource }.not_to change(Group, :count).from(1)
  end

  it 'updates database record' do
    resource

    Group.last.reload.tap do |group|
      expect(group.name).to eq 'xikolo.group'
      expect(group.description).to eq 'Just for testing.'
    end
  end

  it 'returns updated resource' do
    expect(resource).to eq json(Group.last)
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
      expect { resource }.to change(Group, :count).from(1).to(2)
    end

    it 'responds with :created' do
      expect(resource).to respond_with :created
    end
  end
end
