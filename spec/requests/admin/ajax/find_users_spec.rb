# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Ajax: Users: Index', type: :request do
  let(:find_users) { get '/admin/find_users', params:, headers: }
  let(:headers) do
    {
      Authorization: "Xikolo-Session session_id=#{stub_session_id}",
      'X-Requested-With': 'XMLHttpRequest',
    }
  end
  let(:permissions) { %w[account.user.find] }
  let(:params) { {q: 'user'} }
  let(:json) { response.parsed_body }

  let(:user) do
    build(:'account:user', name: 'Jane Doe', email: 'user@example.com')
  end

  before do
    stub_user_request(permissions:)

    Stub.request(
      :account, :get, '/users',
      query: hash_including(query: 'user')
    ).to_return Stub.json([user])
  end

  context 'as an AJAX request' do
    it 'lists all matched courses' do
      find_users
      expect(json).to contain_exactly({'id' => user['id'], 'text' => 'Jane Doe (user@example.com)'})
    end
  end

  context 'without permissions' do
    let(:permissions) { [] }

    it 'responds with 403 Forbidden' do
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
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    it 'does not respond with HTML' do
      expect { find_users }.to raise_error ActionController::RoutingError
    end
  end
end
