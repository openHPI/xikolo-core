# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::V2::Subtitles::Cues do
  include Rack::Test::Methods

  def app
    Xikolo::API
  end

  let(:stub_session_id) { "token=#{SecureRandom.hex(16)}" }
  let!(:cue1) { create(:subtitle_cue, identifier: 1, start: 0, stop: 10, text: 'First caption') }
  let!(:cue2) { create(:subtitle_cue, subtitle_id: cue1.subtitle_id, identifier: 2, start: 11, stop: 20, text: 'Second caption') }
  let(:formatted_start1) { cue1.formatted_start }
  let(:formatted_stop1) { cue1.formatted_stop }
  let(:formatted_start2) { cue2.formatted_start }
  let(:formatted_stop2) { cue2.formatted_stop }
  let(:json) { JSON.parse(response.body) }

  let(:env_hash) do
    {
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'HTTP_AUTHORIZATION' => "Legacy-Token #{stub_session_id}",
    }
  end

  describe 'GET subtitle-cues (filter[track])' do
    subject(:response) { get "/v2/subtitle-cues?filter%5Btrack%5D=#{cue1.subtitle_id}", nil, env_hash }

    it 'responds with 200 Ok' do
      expect(response.status).to eq 200
    end

    it 'responds with all subtitle cues' do
      expect(json['data']).to eq [
        {'type' => 'subtitle-cues',
          'id' => Digest::MD5.hexdigest("#{cue1.subtitle_id}|#{formatted_start1}|#{formatted_stop1}"),
          'attributes' =>
            {'identifier' => '1', 'text' => 'First caption', 'start' => '00:00:00.000', 'end' => nil, 'settings' => ''}},
        {'type' => 'subtitle-cues',
         'id' => Digest::MD5.hexdigest("#{cue2.subtitle_id}|#{formatted_start2}|#{formatted_stop2}"),
         'attributes' =>
           {'identifier' => '2', 'text' => 'Second caption', 'start' => '00:00:11.000', 'end' => nil, 'settings' => ''}},
      ]
    end
  end
end
