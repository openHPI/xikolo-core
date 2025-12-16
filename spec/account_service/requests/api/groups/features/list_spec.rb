# frozen_string_literal: true

require 'spec_helper'

describe 'Groups: Features: Listing', type: :request do
  subject(:resource) { base.rel(:features).get.value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:base) { api.rel(:group).get({id: group}).value! }
  let(:group) { create(:'account_service/group') }

  let!(:features) do
    [
      create_list(:'account_service/feature', 2),
      create_list(:'account_service/feature', 2, owner: group),
      create_list(:'account_service/feature', 2),
    ].flatten
  end

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with features' do
    expect(resource).to eq AccountService::FeaturesDecorator.new(features[2..3]).as_json
  end
end
