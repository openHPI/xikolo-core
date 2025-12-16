# frozen_string_literal: true

require 'spec_helper'

describe 'Grants: Show', type: :request do
  subject(:resource) { grant.follow.get.value! }

  let(:group) { create(:'account_service/group') }
  let(:role)  { create(:'account_service/role') }

  let(:api)   { restify_with_headers(account_service_url).get.value! }
  let(:grant) { api.rel(:grants).post({group: group.to_param, role: role.to_param, context: 'root'}).value! }

  it 'responds with :ok' do
    expect(resource).to respond_with :ok
  end

  it 'returns grant resource' do
    expect(resource).to eq json(AccountService::Grant.last)
  end
end
