# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication: Login with token', type: :request do
  before do
    Stub.service(:account, build(:'account:root'))
  end

  context 'in HTTP Authorization header' do
    subject(:request) do
      get '/', headers: {'HTTP_AUTHORIZATION' => "Token token=#{token}"}
    end

    let(:token) { '3d0eab0dd1dbec94995d92bf5d6b0f2537fee195a87959922a487116d83aa3022316e82be8148d5ed2aacab5b2a10fa963dabffefae685f4a97093789bcc5852' }
    let(:user_id) { 'b668a41c-e8fc-46b8-8f68-2a3c800703b7' }
    let(:new_session_id) { '3463f4c3-d27c-4744-9ef8-7653ccad2f7d' }

    let!(:create_session_stub) do
      Stub.request(
        :account, :post, '/sessions',
        body: {user: user_id}
      ).to_return Stub.json({
        id: new_session_id,
      })
    end

    before do
      # Minimal stub for a token session belonging to a valid user
      Stub.request(
        :account, :get, "/sessions/token=#{token}",
        query: {context: 'root', embed: 'user,permissions,features'}
      ).to_return Stub.json({
        id: nil, # Weird edge case for sessions belonging to tokens
        user_id:,
        user: {
          anonymous: false,
          language: 'en',
          preferred_language: 'en',
          preferences_url: '/preferences',
          permissions_url: stub_url(:account, "/users/#{user_id}/permissions?user_id=#{user_id}"),
        },
      })

      Stub.request(
        :account, :get, '/preferences'
      ).to_return Stub.json({properties: {}})

      Stub.request(
        :account, :get, "/users/#{user_id}/permissions",
        query: {context: 'root', user_id:}
      ).to_return Stub.json([])
    end

    it 'logs the user in' do
      request
      expect(response.body).to include 'Log out'
    end

    it 'creates a new session for the user' do
      request
      expect(create_session_stub).to have_been_requested
    end

    context 'when visiting the site again, without header' do
      subject(:two_visits) { request; get '/' }

      before do
        # Stub the request for the newly created session
        Stub.request(
          :account, :get, "/sessions/#{new_session_id}",
          query: {context: 'root', embed: 'user,permissions,features'}
        ).to_return Stub.json({
          id: new_session_id,
          user_id:,
          user: {
            anonymous: false,
            language: 'en',
            preferred_language: 'en',
            preferences_url: '/preferences',
            permissions_url: stub_url(:account, "/users/#{user_id}/permissions?user_id=#{user_id}"),
          },
        })

        Stub.request(
          :account, :get, '/preferences'
        ).to_return Stub.json({properties: {}})
      end

      it 'remembers the user via cookie' do
        two_visits
        expect(response.body).to include 'Log out'
      end
    end
  end
end
