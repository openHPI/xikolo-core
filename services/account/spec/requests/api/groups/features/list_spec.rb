# frozen_string_literal: true

require 'spec_helper'

describe 'Groups: Features: Listing', type: :request do
  subject(:resource) { base.rel(:features).get.value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:base) { api.rel(:group).get(id: group).value! }
  let(:group) { create(:group) }

  let!(:features) do
    [
      create_list(:feature, 2),
      create_list(:feature, 2, owner: group),
      create_list(:feature, 2),
    ].flatten
  end

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with features' do
    expect(resource).to eq FeaturesDecorator.new(features[2..3]).as_json
  end
end
