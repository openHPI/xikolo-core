# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Xi::Controllers::RequireBearerToken, type: :controller do
  subject(:action) { get :index }

  controller(ActionController::Base) do
    before_action Xi::Controllers::RequireBearerToken.new(
      realm: 'my-realm',
      token: -> { 'super-secret-token' }
    )

    def index
      render plain: 'passed'
    end
  end

  let(:json) { JSON.parse(response.body) }

  context 'without Authorization header' do
    it 'responds with 401 Unauthorized' do
      action
      expect(response).to have_http_status :unauthorized
      expect(response.headers['WWW-Authenticate']).to eq 'Bearer realm="my-realm"'
      expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
      expect(json).to eq(
        'type' => 'https://tools.ietf.org/html/rfc6750#section-3',
        'title' => 'You must provide an Authorization header to access this resource.',
        'status' => 401
      )
    end
  end

  context 'when trying to authorize with an invalid token' do
    before do
      request.headers['Authorization'] = 'Bearer invalid'
    end

    it 'responds with 401 Unauthorized' do
      action
      expect(response).to have_http_status :unauthorized
      expect(response.headers['WWW-Authenticate']).to eq 'Bearer realm="my-realm", error="invalid_token"'
      expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
      expect(json).to eq(
        'type' => 'https://tools.ietf.org/html/rfc6750#section-3.1',
        'title' => 'The bearer token you provided was invalid, has expired or has been revoked.',
        'status' => 401
      )
    end
  end

  context 'when authorized (with a hardcoded token)' do
    before do
      request.headers['Authorization'] = 'Bearer super-secret-token'
    end

    it 'responds with the correct object structure' do
      action
      expect(response).to have_http_status :ok
      expect(response.body).to eq 'passed'
    end
  end
end
