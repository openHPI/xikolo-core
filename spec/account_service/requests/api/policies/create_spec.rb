# frozen_string_literal: true

require 'spec_helper'

describe 'Policy: Create', type: :request do
  subject(:resource) { api.rel(:policies).post(data).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:data) { {version: 1, url: {en: 'https://example.com', de: 'https://example.de'}} }

  it 'responds with a created resource' do
    expect(resource).to respond_with :created
  end

  it 'creates database record' do
    expect { resource }.to change(AccountService::Policy, :count).from(0).to(1)
  end

  it 'saves the provided data' do
    resource
    policy = AccountService::Policy.last
    expect(policy.version).to eq 1
    expect(policy.url['en']).to eq 'https://example.com'
    expect(policy.url['de']).to eq 'https://example.de'
  end

  it 'returns created role' do
    expect(resource).to eq json(AccountService::Policy.last)
  end
end
