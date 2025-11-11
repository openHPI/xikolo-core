# frozen_string_literal: true

require 'spec_helper'

describe 'Memberships: Show', type: :request do
  subject(:resource) { api.rel(:membership).get({id: membership}).value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:membership) { create(:'account_service/membership') }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with membership resource' do
    expect(resource).to eq json(membership)
  end
end
