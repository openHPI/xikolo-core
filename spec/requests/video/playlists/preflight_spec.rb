# frozen_string_literal: true

require 'spec_helper'

describe 'Video: Playlists: Preflight', type: :request do
  subject(:playlist_preflight) do
    # Browsers would send a request like this to check whether cross-origin
    # requests to the playlists are allowed.
    # Chromecast does this too, apparently.
    process :options, "/playlists/#{stream_id}", headers: {
      'HTTP_ORIGIN' => 'https://www.google.com',
      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET',
    }
  end

  let(:stream_id) { '00000001-0002-0003-0004-000000000005' }

  describe '(response)' do
    subject(:resp) { playlist_preflight; response }

    it 'allows cross-origin requests' do
      expect(resp).to have_http_status(:ok)
      expect(resp.headers['Access-Control-Allow-Origin']).to eq('*')
    end
  end
end
