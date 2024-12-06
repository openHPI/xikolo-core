# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::V2::Subtitles::Tracks do
  include Rack::Test::Methods

  def app
    Xikolo::API
  end

  let(:stub_session_id) { "token=#{SecureRandom.hex(16)}" }

  let(:item) { create(:item, content: video) }
  let(:video) { create(:video, :with_subtitles) }
  let(:subtitle_1) { video.subtitles.first }
  let(:subtitle_2) { video.subtitles.last }

  let(:json) { JSON.parse(response.body) }

  let(:env_hash) do
    {
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'HTTP_AUTHORIZATION' => "Legacy-Token #{stub_session_id}",
    }
  end

  describe 'GET subtitle-tracks (filter[video])' do
    subject(:response) { get "/v2/subtitle-tracks?filter[video]=#{video.id}", nil, env_hash }

    let(:json) { JSON.parse response.body }

    it 'responds with 200 Ok' do
      expect(response.status).to eq 200
    end

    it 'responds with all subtitle tracks' do
      expect(json['data']).to eq [
        {
          'type' => 'subtitle-tracks',
          'id' => subtitle_1.id,
          'attributes' => {
            'language' => 'en',
            'created_by_machine' => false,
            'vtt_url' => "https://xikolo.de/subtitles/#{subtitle_1.id}",
          },
          'relationships' => {
            'cues' => {
              'links' => {
                'related' => "/api/v2/subtitle-cues?filter%5Btrack%5D=#{subtitle_1.id}",
              },
            },
          },
        },
        {
          'type' => 'subtitle-tracks',
          'id' => subtitle_2.id,
          'attributes' => {
            'language' => 'de',
            'created_by_machine' => false,
            'vtt_url' => "https://xikolo.de/subtitles/#{subtitle_2.id}",
          },
          'relationships' => {
            'cues' => {
              'links' => {
                'related' => "/api/v2/subtitle-cues?filter%5Btrack%5D=#{subtitle_2.id}",
              },
            },
          },
        },
      ]
    end
  end
end
