# frozen_string_literal: true

require 'spec_helper'

describe 'Transpipe API: Patch subtitle', type: :request do
  subject(:request) do
    patch "/bridges/transpipe/videos/#{video_id}/subtitles/#{language}?automatic=#{automatic}", headers:, params: body
  end

  let(:headers) { {'Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966'} }
  let(:body) { Rails.root.join('spec/support/files/video/subtitles/valid_en.vtt').read }
  let(:json) { JSON.parse response.body }
  let(:video_id) { video.id }
  let(:video) { create(:video, :with_subtitles) }
  let(:subtitle) { video.subtitles.first }
  let(:language) { subtitle.lang }
  let(:automatic) { subtitle.automatic }

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end

  it 'responds with a confirmation' do
    request
    expect(response).to have_http_status :ok
  end

  context 'when video has no subtitles' do
    let(:video) { create(:video) }
    let(:language) { 'en' }
    let(:automatic) { false }

    it 'responds with a confirmation' do
      request
      expect(response).to have_http_status :ok
    end

    it 'creates new subtitles for the video' do
      expect { request }.to change(video.subtitles, :count).from(0).to(1)
    end
  end

  describe 'authorization / error handling' do
    context 'when the body is empty' do
      let(:body) { '' }

      it 'responds with 400 Bad Request and explains the error' do
        request
        expect(response).to have_http_status :bad_request
        expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
        expect(json).to eq(
          'title' => 'The request body cannot be blank.',
          'status' => 400
        )
      end
    end

    context 'when the vtt file has an invalid interval' do
      let(:body) do
        Rails.root.join('spec/support/files/video/subtitles/invalid_en.vtt').read
      end

      it 'responds with HTTP 422 Unprocessable Entity' do
        request

        expect(response).to have_http_status :unprocessable_entity
        expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
        expect(json).to eq(
          'title' => 'Validation failed: Invalid subtitle cue on the WebVTT file at cue 1.',
          'status' => 422
        )
      end
    end

    context 'when the vtt file has multiple invalid intervals' do
      let(:body) do
        Rails.root.join('spec/support/files/video/subtitles/multiple_invalid_en.vtt').read
      end

      it 'responds with HTTP 422 Unprocessable Entity' do
        request
        expect(response).to have_http_status :unprocessable_entity
        expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
        expect(json).to eq(
          'title' => 'Validation failed: Invalid subtitle cues on the WebVTT file at cues 1, 2.',
          'status' => 422
        )
      end
    end

    context 'when the content of the VTT file does not start with WEBVTT' do
      let(:body) do
        Rails.root.join('spec/support/files/video/subtitles/malformed_en.vtt').read
      end

      it 'responds with HTTP 400 Bad Request' do
        request
        expect(response).to have_http_status :bad_request
      end
    end

    context 'when the video cannot be found' do
      let(:video_id) { 'unknown-video' }

      it 'responds with HTTP 404 Not Found' do
        request
        expect(response).to have_http_status :not_found
      end
    end
  end
end
