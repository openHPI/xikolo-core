# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rack::Attack throttling', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  before do
    allow(Rack::Attack.cache).to receive(:store).and_return(ActiveSupport::Cache::MemoryStore.new)

    travel_to(Time.zone.at(0))
  end

  let(:password) { 'wrong-password' }

  def login_request(ip:, email:)
    post '/sessions',
      params: {login: {email: email, password: password}},
      headers: {'REMOTE_ADDR' => ip}
  end

  def reset_request(ip:, email:)
    post '/account/reset',
      params: {reset: {email: email}},
      headers: {'REMOTE_ADDR' => ip}
  end

  describe 'per-email throttling' do
    before do
      allow(Sentry).to receive(:capture_message)
    end

    email = 'student@example.com'

    it 'blocks after limit even if requests come from different IPs' do
      # Your throttle limit is 10
      limit = 10
      # Send 10 requests from different IPs
      limit.times do |i|
        login_request(ip: "192.168.1.#{i}", email: email)
        expect(response.status).not_to eq(429), "Request ##{i + 1} should not be throttled"
      end

      # 11th request from a new IP should be blocked
      login_request(ip: '10.0.0.1', email: email)
      expect(response).to have_http_status(:too_many_requests)

      expect(Sentry).to have_received(:capture_message).with(
        'Rack::Attack throttle triggered',
        hash_including(
          level: :warning
        )
      )
    end
  end

  describe 'login per email throttle' do
    it 'allows up to 10 attempts and blocks the 11th' do
      10.times do
        login_request(ip: '1.1.1.1', email: 'student@example.com')
        expect(response).not_to have_http_status(:too_many_requests)
      end

      login_request(ip: '1.1.1.1', email: 'student@example.com')
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'shared wifi scenario' do
    it 'does not block different emails from same IP' do
      20.times do |i|
        login_request(
          ip: '2.2.2.2',
          email: "student#{i}@example.com"
        )
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end

  describe 'login per IP throttle' do
    it 'blocks after 100 attempts from same IP' do
      100.times do |i|
        login_request(
          ip: '3.3.3.3',
          email: "user#{i}@example.com"
        )
      end

      login_request(ip: '3.3.3.3', email: 'another@example.com')

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'password reset throttle' do
    it 'allows 5 reset attempts and blocks the 6th' do
      5.times do
        reset_request(
          ip: '4.4.4.4',
          email: 'student@example.com'
        )
        expect(response).not_to have_http_status(:too_many_requests)
      end

      reset_request(
        ip: '4.4.4.4',
        email: 'student@example.com'
      )

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'throttle reset after period' do
    it 'resets after 1 minute' do
      10.times do
        login_request(ip: '5.5.5.5', email: 'student@example.com')
      end

      expect(response).not_to have_http_status(:too_many_requests)

      # 11th blocked
      login_request(ip: '5.5.5.5', email: 'student@example.com')
      expect(response).to have_http_status(:too_many_requests)

      # Travel forward past throttle period
      travel 61.seconds
      login_request(ip: '5.5.5.5', email: 'student@example.com')
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end
end
