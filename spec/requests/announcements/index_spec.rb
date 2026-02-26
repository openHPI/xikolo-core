# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Posts: Index', type: :request do
  subject(:get_posts) { get '/news', headers: }

  let(:posts_stub) do
    Stub.request(
      :news, :get, '/posts',
      query: hash_including(language: 'en')
    ).to_return Stub.json([])
  end
  let(:headers) { {} }

  before do
    posts_stub
  end

  context 'for anonymous user' do
    it 'shows the announcements page' do
      get_posts
      expect(response).to be_successful
    end

    it 'requests all published, non-restricted announcements only' do
      get_posts
      expect(
        posts_stub.with(
          query: {published: 'true', language: 'en'}
        )
      ).to have_been_requested.once
    end
  end

  context 'for logged-in user' do
    let(:user) { stub_user_request }
    let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }

    before { user }

    it 'shows the announcements page' do
      get_posts
      expect(response).to be_successful
    end

    it 'requests all published, user-restricted announcements only' do
      get_posts
      expect(
        posts_stub.with(
          query: {published: 'true', user_id: user[:id], language: 'en'}
        )
      ).to have_been_requested.once
    end

    context 'with permission to see all announcements' do
      let(:user) do
        stub_user_request permissions: ['news.announcement.show']
      end

      it 'shows the announcements page' do
        get_posts
        expect(response).to be_successful
      end

      it 'requests all announcements (including unpublished and restricted)' do
        get_posts
        expect(
          posts_stub.with(
            query: {published: 'false', user_id: user[:id], language: 'en'}
          )
        ).to have_been_requested.once
      end
    end
  end
end
