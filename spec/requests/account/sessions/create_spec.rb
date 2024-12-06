# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Sessions: Create', type: :request do
  before do
    Stub.service(:news, build(:'news:root'))

    Stub.request(:news, :get, '/news')
      .with(query: hash_including({}))
      .to_return Stub.json([])
  end

  around(&With(:csrf_protection, true))

  context 'without CSRF token' do
    it 'renders login page' do
      post '/sessions', params: {
        login: {
          email: 'admin@xikolo.de',
          password: 'secret',
        },
      }

      expect(response).to redirect_to '/sessions/new'
    end
  end
end
