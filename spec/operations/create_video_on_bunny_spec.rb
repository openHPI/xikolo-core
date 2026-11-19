# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateVideoOnBunny do
  subject(:call) { described_class.new(library_id: 'lib-123', title: 'My Short').call }

  let(:bunny_url) { 'https://video.bunnycdn.com/library/lib-123/videos' }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('BUNNY_VIDEO_API_KEY').and_return('test-key')
  end

  context 'when the request succeeds' do
    before do
      stub_request(:post, bunny_url)
        .to_return(status: 200, body: {guid: 'video-guid-123'}.to_json)
    end

    it 'returns the video guid' do
      expect(call).to eq 'video-guid-123'
    end
  end

  context 'when collection_id is provided' do
    subject(:call) { described_class.new(library_id: 'lib-123', title: 'My Short', collection_id: 'col-456').call }

    before do
      stub_request(:post, bunny_url)
        .with(body: hash_including('collectionId' => 'col-456'))
        .to_return(status: 200, body: {guid: 'video-guid-123'}.to_json)
    end

    it 'returns the video guid' do
      expect(call).to eq 'video-guid-123'
    end
  end

  context 'when the credentials are rejected' do
    before do
      stub_request(:post, bunny_url).to_return(status: 401, body: 'Unauthorized')
    end

    it 'raises a Bunny error' do
      expect { call }.to raise_error(Video::Bunny::Error, /HTTP 401/)
    end
  end

  context 'when the video is not found' do
    before do
      stub_request(:post, bunny_url).to_return(status: 404, body: 'Not Found')
    end

    it 'raises a Bunny error' do
      expect { call }.to raise_error(Video::Bunny::Error, /HTTP 404/)
    end
  end

  context 'when the provider is temporarily unavailable' do
    before do
      stub_request(:post, bunny_url).to_return(status: 503, body: 'Service Unavailable')
    end

    it 'raises a Bunny error' do
      expect { call }.to raise_error(Video::Bunny::Error, /HTTP 503/)
    end
  end

  context 'when the provider cannot be reached' do
    before do
      stub_request(:post, bunny_url).to_raise(Errno::ECONNREFUSED)
    end

    it 'raises a Bunny error' do
      expect { call }.to raise_error(Video::Bunny::Error, /ECONNREFUSED/)
    end
  end
end
