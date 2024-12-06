# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Web Manifest: Show', type: :request do
  subject(:show_manifest) { get '/web_manifest.json' }

  before do
    xi_config <<~YML
      webapp:
        native_apps:
          play: 'de.xikolo.sample'
    YML
  end

  it 'responds with the complete manifest' do
    show_manifest
    expect(response).to be_successful
    expect(response.parsed_body).to eq \
      'name' => 'Xikolo',
      'short_name' => 'Xikolo',
      'start_url' => '/dashboard?tracking_campaign=web_app_manifest',
      'display' => 'standalone',
      'icons' => [],
      'prefer_related_applications' => true,
      'related_applications' => [{'id' => 'de.xikolo.sample', 'platform' => 'play'}]
  end

  context 'with background color' do
    before do
      xi_config <<~YML
        webapp:
          bg_color: '#ffffff'
      YML
    end

    it 'includes the background color in the manifest' do
      show_manifest
      expect(response).to be_successful
      expect(response.parsed_body).to include \
        'background_color' => '#ffffff'
    end
  end
end
