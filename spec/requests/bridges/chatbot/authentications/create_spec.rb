# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Chatbot Bridge API: Authentications: Create', type: :request do
  subject(:request) do
    post '/bridges/chatbot/authenticate', headers:, params:
  end

  let(:authorization_token) { 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966' }
  let(:headers) { {'Authorization' => authorization_token} }
  let(:params) { {uid: '48f702d1-65e6-4aa2-acff-7594fcb0f9bd'} }
  let(:user) { create(:user) }
  let(:signed_token) { TokenSigning.for(:chatbot).sign(user.id) }
  let(:json) { JSON.parse response.body }

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with missing SAML UID' do
    let(:params) { {} }

    it 'complains about missing parameter' do
      request
      expect(response).to have_http_status :not_found
      expect(json['title']).to eq('A valid authorization ID must be provided in the request body to generate a token for a user.')
    end
  end

  context 'with existing user for the provided SAML UID' do
    before do
      create(:authorization, user:, uid: params[:uid], provider: 'saml')
    end

    it 'returns a signed token that can be used to authenticate with other endpoints' do
      request

      # Use the token returned from the authentication request to authenticate the next request
      get '/bridges/chatbot/user', headers: {'Authorization' => "Bearer #{json['token']}"}

      # The user ID can be read from the second endpoint's response
      expect(JSON.parse(response.body)).to eq({'id' => user.id})
    end
  end

  context 'without existing user for the provided SAML UID' do
    before do
      create(:authorization, user:, uid: '12345', provider: 'saml')
    end

    it 'indicates that the user cannot be found' do
      request
      expect(response).to have_http_status :not_found
      expect(json['title']).to eq('There is no user for the provided authorization ID.')
    end
  end
end
