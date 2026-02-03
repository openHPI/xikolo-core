# frozen_string_literal: true

require 'spec_helper'

describe 'APIv2: Show root features', type: :request do
  subject(:request) { get "/api/v2/course-features/#{course_id}", headers: }

  let(:base_headers) { {Content_Type: 'application/vnd.api+json'} }
  let(:authorization_headers) { {} }
  let(:headers) { base_headers.merge(authorization_headers) }

  let(:stub_session_id) { "token=#{SecureRandom.hex(16)}" }
  let(:user_id) { generate(:user_id) }

  let(:course_id) { SecureRandom.uuid }
  let(:context_id) { SecureRandom.uuid }
  let(:features) { {'feature_1' => 't', 'feature_2' => 't'} }

  before do
    Stub.request(:account, :get, "/users/#{user_id}")
      .and_return Stub.json build(:'account:user', id: user_id)
    Stub.request(:account, :get, "/users/#{user_id}/features?context=#{context_id}")
      .and_return Stub.json features

    Stub.request(:course, :get, "/courses/#{course_id}")
      .and_return Stub.json build(:'course:course', id: course_id, context_id:)

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

      it 'contains the correct id' do
        request
        id = json.dig('data', 'id')
        expect(id).to match course_id
      end

      it 'contains the specified features' do
        request
        features = json.dig('data', 'attributes', 'features')
        expect(features).to match_array %w[feature_1 feature_2]
      end
    end

    context 'for an invalid course id' do
      before do
        Stub.request(:course, :get, "/courses/#{course_id}")
          .and_return Stub.response(status: 404)
      end

      it 'returns not found' do
        request
        expect(response).to have_http_status :not_found
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
