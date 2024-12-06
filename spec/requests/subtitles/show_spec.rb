# frozen_string_literal: true

require 'spec_helper'

describe 'Video: Subtitles: Show', type: :request do
  let(:show_subtitles) { get "/subtitles/#{subtitle_id}" }

  let!(:cue) { create(:subtitle_cue, identifier: 1, start: 0, stop: 10) }
  let(:subtitle) { cue.subtitle }
  let(:subtitle_id) { subtitle.id }

  describe '(response)' do
    context 'when requesting VTT representation' do
      it 'allows cross-origin requests' do
        show_subtitles
        expect(response).to have_http_status(:ok)
        expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
      end

      it 'responds with subtitles in WebVTT format' do
        show_subtitles
        expect(response.body).to match "WEBVTT\n\n1\n00:00:00.000 --> 00:00:10.000 \nLorem ipsum dolor sit amet, consectetur adipiscing elit.\n"
      end

      it 'responds with the correct MIME type' do
        show_subtitles
        expect(response['Content-Type']).to eq 'text/vtt; charset=utf-8'
      end
    end

    context 'with an invalid subtitles id' do
      let(:subtitle_id) { SecureRandom.uuid }

      it 'responds with 404 Not Found' do
        show_subtitles
        expect(response).to have_http_status :not_found
      end

      it 'responds with plain text' do
        show_subtitles
        expect(response['Content-Type']).to eq 'text/plain'
      end
    end
  end
end
