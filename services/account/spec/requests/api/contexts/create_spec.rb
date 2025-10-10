# frozen_string_literal: true

require 'spec_helper'

describe 'Context: Creation', type: :request do
  subject(:resource) { api.rel(:contexts).post(data).value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:data) { {} }

  it 'responds with a created status' do
    expect(resource).to respond_with :created
  end

  it 'responds with a follow location to the created resource' do
    expect(resource.follow).to eq account_service.context_url(Context.non_root.last)
  end

  it 'creates a database record' do
    expect { resource }.to change { Context.non_root.count }.from(0).to(1)
  end

  it 'returns the created group' do
    expect(resource).to eq json(Context.non_root.last)
  end

  it 'inherits from root context' do
    expect(resource['parent_id']).to eq Context.root_id
  end

  context 'with reference' do
    let(:data) do
      {reference_uri: 'urn:ietf:rfc:8141'}
    end

    it 'responds with a created status' do
      expect(resource).to respond_with :created
    end

    it 'stored given reference' do
      resource
      expect(Context.non_root.last.reference_uri).to eq 'urn:ietf:rfc:8141'
    end

    it 'returns with given reference' do
      expect(resource['reference_uri']).to eq 'urn:ietf:rfc:8141'
    end
  end
end
