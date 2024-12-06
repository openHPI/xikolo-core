# frozen_string_literal: true

require 'spec_helper'

describe FilesController, type: :controller do
  let(:user_id) { '00000001-3100-4444-9999-000000000003' }

  before do
    stub_request(:get, 'https://secure.gravatar.com/avatar/45ef05f0dd75a5b4fc8d56cfba66783e?d=retro&s=100')
      .with(headers: {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Ruby'})
      .to_return(status: 200, body: 'somebindata', headers: {})
  end

  describe 'GET avatar with 200 for custom user image' do
    subject(:request) { get :avatar, params: {id: user_id} }

    before do
      stub_user id: nil, language: 'en', admin: true

      # Userstub
      Stub.request(
        :account, :get, "/users/#{user_id}"
      ).to_return Stub.json({
        id: user_id,
        avatar_url: 'https://s3.xikolo.de/xikolo-public/avatar/003.jpg',
        email: 'test@example.de',
      })
    end

    it 'redirects to avatar_url' do
      expect(request.status).to eq 302
      expect(request).to redirect_to 'https://s3.xikolo.de/xikolo-public/avatar/003.jpg'
    end
  end

  describe 'GET avatar with no user image set file' do
    subject(:request) { get :avatar, params: {id: user_id} }

    before do
      stub_user id: nil, language: 'en'

      # Userstub
      Stub.request(
        :account, :get, "/users/#{user_id}"
      ).to_return Stub.json({
        id: user_id,
        avatar_url: nil,
        email: 'test@example.de',
      })
    end

    it 'redirects to local default image' do
      expect(request.status).to eq 302
    end
  end
end
