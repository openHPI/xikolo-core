# frozen_string_literal: true

require 'spec_helper'

describe 'Portal API: Delete user', type: :request do
  subject(:request) do
    delete "/portalapi-beta/users/#{auth_id}", headers:
  end

  let(:headers) { {} }
  let(:json) { JSON.parse(response.body).symbolize_keys }
  let(:authorization) { build(:'account:authorization') }
  let(:auth_id) { authorization['uid'] }

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.request(:account, :get, '/authorizations', query: {uid: auth_id})
      .to_return Stub.json([authorization])
  end

  context 'without Authorization header' do
    it 'responds with 401 Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
      expect(response.headers['WWW-Authenticate']).to eq 'Bearer realm="test-realm"'
      expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
      expect(json).to eq(
        type: 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#unauthenticated',
        title: 'You must provide an Authorization header to access this resource.',
        status: 401
      )
    end
  end

  context 'when trying to authorize with an invalid token' do
    let(:headers) do
      super().merge('Authorization' => 'Bearer canihackyou')
    end

    it 'responds with 401 Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
      expect(response.headers['WWW-Authenticate']).to eq 'Bearer realm="test-realm", error="invalid_token"'
      expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
      expect(json).to eq(
        type: 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#invalid_token',
        title: 'The bearer token you provided was invalid, has expired or has been revoked.',
        status: 401
      )
    end
  end

  context 'when authorized (with a hardcoded token)' do
    let(:headers) do
      super().merge('Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966')
    end

    let!(:delete_user_stub) do
      Stub.request(:account, :delete, "/users/#{authorization['user_id']}")
        .to_return Stub.json({id: authorization['user_id']})
    end

    before { request }

    it { expect(response).to have_http_status :no_content }
    it { expect(delete_user_stub).to have_been_requested }
  end
end
