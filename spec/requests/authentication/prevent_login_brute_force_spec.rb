# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Prevent brute force login attempts', type: :request do
  # Remove localhost from the safelist and reset cache to make tests work as expected
  around do |example|
    removed_safelist = Rack::Attack.safelists.delete('allow from localhost')

    example.run
  ensure
    Rack::Attack.safelists['allow from localhost'] = removed_safelist
  end

  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack::Allow2Ban.reset('127.0.0.1', findtime: 1.minute)
  end

  context 'with failed login attempts' do
    before do
      Stub.request(
        :account, :post, '/sessions',
        body: {id: nil, user_id: nil, user_agent: nil, ident: 'p3k@example.de', password: 'p3k'}.to_json
      ).to_return status: :not_found
    end

    let(:anonymous_session) do
      super().merge('features' => {'account.login' => true})
    end

    it 'blocks after 15th failed login attempt' do
      15.times do
        post '/sessions', params: {
          login: {email: 'p3k@example.de', password: 'p3k'},
        }

        expect(response).to have_http_status(:found)
      end

      post '/sessions', params: {
        login: {email: 'p3k@example.de', password: 'p3k'},
      }

      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to eq 'Blocked due to too many login attempts.'

      # Does not block resources other than '/sessions'
      get '/'
      expect(response).to have_http_status :ok
    end
  end

  context 'with successful logins' do
    let(:session_id) { SecureRandom.uuid }
    let(:user_id) { SecureRandom.uuid }
    let(:anonymous_session) do
      super().merge('features' => {'account.login' => true})
    end

    before do
      Stub.request(
        :account, :post, '/sessions',
        body: {id: nil, user_id: nil, user_agent: nil, ident: 'p3k@example.de', password: 'p3k'}.to_json
      ).to_return Stub.json({
        id: session_id,
        user_id:,
      })

      Stub.request(
        :account, :get, '/policies'
      ).to_return Stub.json([])

      Stub.request(
        :account, :get, "/sessions/#{session_id}",
        query: {context: 'root', embed: 'user,permissions,features'}
      ).to_return Stub.json({
        id: session_id,
        user_id:,
        user: {anonymous: false, language: 'en', preferred_language: 'en'},
        features: {'account.login' => true},
      })
    end

    it 'does not block after 15th successful login' do
      16.times do
        post '/sessions', params: {
          login: {email: 'p3k@example.de', password: 'p3k'},
        }

        expect(response).to have_http_status(:found)
      end
    end
  end
end
