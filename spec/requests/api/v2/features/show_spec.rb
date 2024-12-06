# frozen_string_literal: true

require 'spec_helper'

describe 'APIv2: Show root features', type: :request do
  subject(:request) { get '/api/v2/features/', headers: }

  let(:base_headers) { {Content_Type: 'application/vnd.api+json'} }
  let(:authorization_headers) { {} }
  let(:headers) { base_headers.merge(authorization_headers) }

  let(:stub_session_id) { "token=#{SecureRandom.hex(16)}" }
  let(:user_id) { generate(:user_id) }

  let(:features) { {'feature_1' => 't', 'feature_2' => 't'} }

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.request(:account, :get, "/users/#{user_id}")
      .and_return Stub.json build(:'account:user', id: user_id)
    Stub.request(:account, :get, "/users/#{user_id}/features")
      .and_return Stub.json features

    api_stub_user id: user_id
  end

  context 'for authenticated users' do
    let(:authorization_headers) { {Authorization: "Legacy-Token #{stub_session_id}"} }

    it 'responds successfully' do
      request
      expect(response).to have_http_status :ok
    end

    describe '(json)' do
      subject(:json) { JSON.parse response.body }

      it 'contains the specified features' do
        request
        features = json.dig('data', 'attributes', 'features')
        expect(features).to match_array %w[feature_1 feature_2]
      end
    end
  end

  context 'for anonymous users' do
    it 'responds with Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end
end
