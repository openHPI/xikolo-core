# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Stream: Sync: Create', type: :request do
  subject(:sync) { post "/streams/#{stream_id}/sync", headers: }

  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:stream) { create(:stream, provider:, provider_video_id: '207611533') }
  let(:stream_id) { stream.id }
  let(:provider) { create(:video_provider, :vimeo) }
  let(:permissions) { [] }

  before { stub_user_request(permissions:) }

  describe '(response)' do
    it 'is forbidden without proper permissions' do
      sync
      expect(response).to redirect_to root_url
      expect(request.flash['error'].first).to eq 'You do not have sufficient permissions for this action.'
    end

    context 'with permission' do
      let(:permissions) { %w[video.video.index] }

      let(:provider_url) do
        "https://api.vimeo.com/videos/#{stream.provider_video_id}?fields=uri,name,duration,width,height,status,modified_time,pictures.sizes.link,pictures.sizes.width,files.quality,files.size,files.md5,files.link,download"
      end

      let!(:provider_request) do
        stub_request(:get, provider_url)
          .with(headers: {
            'Authorization' => "Bearer #{provider.credentials['token']}",
            'Accept' => 'application/vnd.vimeo.*+json;version=3.4',
          })
          .to_return(body: provider_response)
      end

      let(:provider_response) { File.read 'spec/support/files/video/vimeo/video/full_response.json' }

      it 'calls the video provider API' do
        sync
        expect(provider_request).to have_been_requested.once
      end

      it 'does not store a new stream' do
        expect { sync }.not_to change(Video::Stream, :count)
      end

      it 'updates the stream data' do
        sync
        stream.reload

        # See full_response.json for new data
        expect(stream.title).to eq 'nanou-webtech2017-w1-1-pip-p1'
        expect(stream.poster).to eq 'https://i.vimeocdn.com/video/622733127_1920x1080.jpg?r=pad'
      end

      context 'for non-existing stream' do
        let(:stream_id) { SecureRandom.uuid }

        it 'shows an error message' do
          sync
          expect(response).to redirect_to videos_url
          expect(request.flash['error'].first).to eq 'The video could not be synced.'
        end
      end
    end

    context 'for anonymous user' do
      let(:headers) { {} }

      it 'redirects to login page' do
        sync
        expect(response).to redirect_to 'http://www.example.com/sessions/new'
      end
    end
  end
end
