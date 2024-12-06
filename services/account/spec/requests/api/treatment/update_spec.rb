# frozen_string_literal: true

require 'spec_helper'

describe 'Update treatment', type: :request do
  subject(:resource) { api.rel(:treatment).patch(data, id: record.id).value! }

  let(:api) { Restify.new(:test).get.value! }

  let(:record) { create(:treatment) }
  let(:data) { {} }

  it 'responds with FORBIDDEN' do
    expect { resource }.to raise_error(Restify::ClientError) do |e|
      expect(e.status).to eq :forbidden
    end
  end
end
