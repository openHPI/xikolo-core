# frozen_string_literal: true

require 'spec_helper'

describe ShortsController, type: :controller do
  describe '#signed_url' do
    subject(:action) { get :signed_url, params: {id: short.id} }

    let(:status) { 'active' }

    let(:short) { create(:'course_service/short', bunny_video_id: 'video-guid', status: status) }
    let(:signed) do
      {
        video: 'https://vz-test.b-cdn.net/video-guid/playlist.m3u8?token=tok',
        thumbnail: 'https://vz-test.b-cdn.net/video-guid/thumbnail.jpg?token=tok',
      }
    end
    let(:signer) { instance_double(BunnySignedURL, call: signed) }

    before do
      allow(BunnySignedURL).to receive(:new).and_return(signer)
    end

    it 'redirects to the signed video URL' do
      action

      expect(response).to have_http_status :found
      expect(response).to redirect_to signed.fetch(:video)
    end

    it 'signs the URL using the bunny_video_id of the short' do
      action

      expect(signer).to have_received(:call).with('video-guid')
    end

    it 'is accessible to anonymous users' do
      action

      expect(response).to have_http_status :found
    end

    context 'when the short is not active' do
      subject(:action) { get :signed_url, params: {id: short.id} }

      let(:status) { 'preparation' }

      it 'raises a not found error' do
        expect { action }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the short does not exist' do
      subject(:action) { get :signed_url, params: {id: SecureRandom.uuid} }

      it 'raises a not found error' do
        expect { action }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
