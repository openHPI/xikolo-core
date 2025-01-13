# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Lanalytics Bridge API: Video Stats: Show', type: :request do
  subject(:show_stats) do
    get "/bridges/lanalytics/videos/#{video_id}/video_stats", headers:
  end

  let(:video_id) { video.id }
  let(:video) { create(:video) }
  let(:token) { 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966' }
  let(:headers) { {'Authorization' => token} }
  let(:json) { JSON.parse response.body }

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      show_stats

      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with an existing video' do
    it 'responds with the correct video stats' do
      show_stats

      expect(json).to eq({
        'duration' => video.duration,
      })
    end
  end

  context 'with an unknown video' do
    let(:video_id) { generate(:uuid) }

    it 'responds with 404 Not Found' do
      show_stats

      expect(json).to be_empty
      expect(response).to have_http_status :not_found
    end
  end
end
