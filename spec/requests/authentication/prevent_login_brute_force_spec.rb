# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Prevent brute force login attempts', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:remote_ip) { '1.2.3.4' }

  def login_request(email:, password: 'p3k')
    post '/sessions',
      params: {login: {email:, password:}},
      headers: {'REMOTE_ADDR' => remote_ip},
      env: {'action_dispatch.remote_ip' => remote_ip}
  end

  before do
    allow(Rack::Attack.cache).to receive(:store).and_return(ActiveSupport::Cache::MemoryStore.new)

    travel_to(Time.zone.at(0))
  end

  context 'with failed login attempts' do
    before do
      Stub.request(
        :account, :post, '/sessions',
        body: {id: nil, user_id: nil, user_agent: nil, ident: 'p3k@example.de', password: 'p3k'}.to_json
      ).to_return status: :not_found
    end

    it 'blocks after 15th failed login attempt' do
      # First window
      10.times do
        login_request(email: 'p3k@example.de')
        expect(response).to have_http_status(:found)
      end

      # Move safely into next Rack::Attack window
      travel 61.seconds

      # Continue attempts
      5.times do
        login_request(email: 'p3k@example.de')
        expect(response).to have_http_status(:found)
      end

      # This should now be blocked
      login_request(email: 'p3k@example.de')

      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to eq 'Blocked due to too many login attempts.'

      # Ensure other routes are not blocked
      get '/'
      expect(response).to have_http_status :ok
    end
  end

  context 'with successful logins' do
    let(:session_id) { SecureRandom.uuid }
    let(:user_id) { SecureRandom.uuid }

    before do
      Stub.request(
        :account, :post, '/sessions',
        body: {id: nil, user_id: nil, user_agent: nil, ident: 'p3k1@example.de', password: 'p3k'}.to_json
      ).to_return Stub.json({
        id: session_id,
        user_id:,
      })

      Stub.request(
        :account, :get, "/sessions/#{session_id}",
        query: {context: 'root', embed: 'user,permissions,features'}
      ).to_return Stub.json({
        id: session_id,
        user_id:,
        user: {anonymous: false, language: 'en', preferred_language: 'en'},
        features: {},
      })
    end

    it 'does not block after 15th successful login' do
      10.times do
        login_request(email: 'p3k1@example.de')
        expect(response).to have_http_status(:see_other)
      end

      travel 61.seconds

      6.times do
        login_request(email: 'p3k1@example.de')
        expect(response).to have_http_status(:see_other)
      end
    end
  end
end
