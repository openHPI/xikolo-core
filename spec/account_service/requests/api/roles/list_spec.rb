# frozen_string_literal: true

require 'spec_helper'

describe 'Role: List', type: :request do
  subject(:resource) { api.rel(:roles).get.value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let!(:roles) { AccountService::Role.all }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with list of roles' do
    expect(resource).to match_array json(roles)
  end
end
