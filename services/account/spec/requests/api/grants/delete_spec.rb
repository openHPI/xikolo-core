# frozen_string_literal: true

require 'spec_helper'

describe 'Grants: Delete', type: :request do
  subject(:delete_grant) { resource.rel(:self).delete.value! }

  let(:group)    { create(:group) }
  let(:role)     { create(:role) }
  let!(:grant)   { create(:grant, principal: group, role:) }

  let(:api)      { Restify.new(:test).get.value! }
  let(:resource) { api.rel(:grant).get({id: grant.id}).value! }

  it 'responds with :ok' do
    expect(delete_grant).to respond_with :ok
  end

  it 'returns grant resource' do
    expect { delete_grant }.to change(Grant, :count).by(-1)
  end
end
