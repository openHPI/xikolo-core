# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Ajax: Users: Index', type: :request do
  let(:find_users) { get '/admin/find_users', params:, headers: }
  let(:headers) { {'X-Requested-With': 'XMLHttpRequest'} }
  let(:params) { {q: 'user'} }
  let(:json) { response.parsed_body }

  let(:user) do
    attributes_for(:'account_service/user', id: generate(:user_id), name: 'Jane Doe', email: 'user@example.com')
  end

  before do
    Stub.request(
      :account, :get, '/users',
      query: hash_including(query: 'user')
    ).to_return Stub.json([user])
  end

  context 'as an AJAX request' do
    it 'lists all matched courses' do
      sign_in(user: create('account_service/user', :gdpr_admin))
      find_users
      expect(json).to contain_exactly({'id' => user[:id], 'text' => 'Jane Doe (user@example.com)'})
    end
  end

  context 'without permissions' do
    it 'responds with 403 Forbidden' do
      sign_in
      find_users
      expect(response).to have_http_status :forbidden
    end
  end

  context 'for anonymous users' do
    let(:headers) { {'X-Requested-With': 'XMLHttpRequest'} }

    it 'responds with 403 Forbidden' do
      find_users
      expect(response).to have_http_status :forbidden
    end
  end

  context 'as an HTTP request' do
    let(:headers) { {} }

    it 'does not respond with HTML' do
      expect { find_users }.to raise_error ActionController::RoutingError
    end
  end
end
