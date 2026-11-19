# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UploadVideoOnBunny do
  subject(:call) { described_class.new(library_id: 'lib-123', video_id: 'vid-456', video_attachment: attachment).call }

  let(:tempfile) { StringIO.new('video data') }
  let(:blob) { instance_double(ActiveStorage::Blob) }
  let(:attachment) { double('video_attachment', blob:) } # rubocop:disable RSpec/VerifiedDoubles
  let(:bunny_url) { 'https://video.bunnycdn.com/library/lib-123/videos/vid-456' }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('BUNNY_VIDEO_API_KEY').and_return('test-key')
    allow(blob).to receive(:open).and_yield(tempfile)
  end

  context 'when the request succeeds' do
    before do
      stub_request(:put, bunny_url)
        .to_return(status: 200, body: {status: 'ok'}.to_json)
    end

    it 'does not raise' do
      expect { call }.not_to raise_error
    end
  end

  context 'when the credentials are rejected' do
    before do
      stub_request(:put, bunny_url).to_return(status: 401, body: 'Unauthorized')
    end

    it 'raises a Bunny error' do
      expect { call }.to raise_error(Video::Bunny::Error, /HTTP 401/)
    end
  end

  context 'when the video is not found' do
    before do
      stub_request(:put, bunny_url).to_return(status: 404, body: 'Not Found')
    end

    it 'raises a Bunny error' do
      expect { call }.to raise_error(Video::Bunny::Error, /HTTP 404/)
    end
  end

  context 'when the provider is temporarily unavailable' do
    before do
      stub_request(:put, bunny_url).to_return(status: 503, body: 'Service Unavailable')
    end

    it 'raises a Bunny error' do
      expect { call }.to raise_error(Video::Bunny::Error, /HTTP 503/)
    end
  end

  context 'when the provider cannot be reached' do
    before do
      stub_request(:put, bunny_url).to_raise(Net::OpenTimeout)
    end

    it 'raises a Bunny error' do
      expect { call }.to raise_error(Video::Bunny::Error, /Net::OpenTimeout/)
    end
  end
end
