# frozen_string_literal: true

require 'spec_helper'

describe 'Policy: List', type: :request do
  subject(:resource) { api.rel(:policies).get.value! }

  let(:api) { Restify.new(:test).get.value! }
  let!(:oldest_policy) { create(:policy, version: 1) }
  let!(:latest_policy) { create(:policy, version: 5) }
  let!(:older_policy) { create(:policy, version: 4) }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with latest policy' do
    expect(resource.size).to eq 3
    expect(resource).to match_array json([latest_policy, older_policy, oldest_policy])
  end
end
