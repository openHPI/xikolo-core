# frozen_string_literal: true

require 'spec_helper'

describe 'Transpipe API: Show subtitle', type: :request do
  subject(:request) { get "/bridges/transpipe/videos/#{video_id}/subtitles/#{language}", headers: }

  let(:headers) { {'Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966'} }
  let(:cue) { create(:subtitle_cue, identifier: 1, start: 0, stop: 10) }
  let(:subtitle) { cue.subtitle }
  let(:video_id) { subtitle.video_id }
  let(:language) { subtitle.lang }

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end

  it 'responds with the proper content type, and the WEBVTT as the response body' do
    request
    expect(response).to have_http_status :ok
    expect(response.headers['Content-Type']).to eq 'text/vtt; charset=utf-8'
    expect(response.body).to eq "WEBVTT\n\n1\n00:00:00.000 --> 00:00:10.000 \nLorem ipsum dolor sit amet, consectetur adipiscing elit.\n"
  end

  describe 'authorization / error handling' do
    context 'when the video does not have the requested subtitle language' do
      let(:language) { 'es' }

      it 'responds with 404 Not Found' do
        request
        expect(response.body).to be_empty
        expect(response).to have_http_status :not_found
      end
    end

    context 'when the video is not found' do
      subject(:request) { get "/bridges/transpipe/videos/#{video_id}/subtitles/#{language}", headers: }

      let(:video_id) { generate(:uuid) }

      it 'responds with 404 Not Found' do
        request
        expect(response).to have_http_status :not_found
      end
    end
  end
end
