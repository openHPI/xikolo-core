# frozen_string_literal: true

require 'spec_helper'

describe 'Users: Show', type: :request do
  subject(:request) do
    get '/bridges/chatbot/user/', headers:
  end

  let(:user_id) { generate(:user_id) }
  let(:token) { "Bearer #{TokenSigning.for(:chatbot).sign(user_id)}" }
  let(:json) { JSON.parse response.body }

  before do
    request
  end

  context 'without Authorization header' do
    let(:headers) { {} }

    it 'complains about missing authorization' do
      expect(response).to have_http_status :unauthorized
      expect(json['title']).to eq('You must provide an Authorization header to access this resource.')
    end
  end

  context 'with Invalid Signature' do
    let(:token) { 'Bearer 123123' }
    let(:headers) { {'Authorization' => token} }

    it 'complains about an invalid signature' do
      expect(response).to have_http_status :unauthorized
      expect(json['title']).to eq('Invalid Signature')
    end
  end

  context 'with valid token' do
    let(:token) { "Bearer #{TokenSigning.for(:chatbot).sign(user_id)}" }
    let(:headers) { {'Authorization' => token} }

    it 'returns plain user id as json' do
      expect(json).to eq({'id' => user_id})
    end
  end
end
