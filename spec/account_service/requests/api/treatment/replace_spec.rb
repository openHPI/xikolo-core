# frozen_string_literal: true

require 'spec_helper'

describe 'Replace treatment', type: :request do
  subject(:resource) { api.rel(:treatment).put(data, params: {id: record.id}).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }

  let(:record) { create(:'account_service/treatment') }
  let(:data) { {} }

  it 'responds with FORBIDDEN' do
    expect { resource }.to raise_error(Restify::ClientError) do |e|
      expect(e.status).to eq :forbidden
    end
  end
end
