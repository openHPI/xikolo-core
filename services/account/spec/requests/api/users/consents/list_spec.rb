# frozen_string_literal: true

require 'spec_helper'

describe 'List user consents', type: :request do
  subject(:resource) { base.rel(:consents).get({}, {**kwargs}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:base) { api.rel(:user).get(id: user).value! }
  let(:kwargs) { {} }

  let(:user) { create(:user) }

  let!(:treatments) do
    create_list(:treatment, 3).each_with_index do |treatment, i|
      treatment.update!(required: i.even?)
    end
  end

  let!(:consent) { create(:consent, user:, treatment: treatments[1]) }
  let!(:denied_consent) { create(:consent, user:, treatment: treatments[2], value: false) }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with list of consents' do
    expect(resource.size).to eq 3

    expect(resource[0]).to match \
      'name' => treatments[0].name,
      'required' => true,
      'consented' => nil,
      'self_url' => user_consent_url(user, treatments[0])

    expect(resource[1]).to match \
      'name' => treatments[2].name,
      'required' => true,
      'consented' => false,
      'consented_at' => denied_consent.consented_at.iso8601(0),
      'self_url' => user_consent_url(user, treatments[2])

    expect(resource[2]).to match \
      'name' => treatments[1].name,
      'required' => false,
      'consented' => true,
      'consented_at' => consent.consented_at.iso8601(0),
      'self_url' => user_consent_url(user, treatments[1])
  end
end
