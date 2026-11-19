# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UploadStreamToBunnyJob, type: :job do
  subject(:perform_job) { described_class.perform_now(stream.id) }

  let(:stream) { create(:stream, :bunny, :with_video) }
  let(:create_double) { instance_double(CreateVideoOnBunny, call: 'bunny-guid-1') }
  let(:upload_double) { instance_double(UploadVideoOnBunny, call: nil) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('BUNNY_VIDEO_LIBRARY_ID').and_return('lib-123')
    allow(ENV).to receive(:fetch).with('BUNNY_VIDEO_CDN_HOST', anything).and_return('cdn.example.com')
    allow(CreateVideoOnBunny).to receive(:new).and_return(create_double)
    allow(UploadVideoOnBunny).to receive(:new).and_return(upload_double)
  end

  context 'when the stream has no video' do
    let(:stream) { create(:stream, :bunny, provider_video_id: 'bunny-guid-1', hls_url: 'https://cdn.example.com/bunny-guid-1/playlist.m3u8') }

    it 'does not create or upload a video' do
      perform_job
      expect(CreateVideoOnBunny).not_to have_received(:new)
      expect(UploadVideoOnBunny).not_to have_received(:new)
    end

    it 'does not change the upload state' do
      perform_job
      expect(stream.reload.upload_state).to eq 'ready'
    end
  end

  context 'when the stream already has a provider video id' do
    let(:stream) do
      create(:stream, :bunny, :with_video,
        provider_video_id: 'existing-guid', hls_url: 'https://cdn.example.com/existing-guid/playlist.m3u8')
    end

    it 'uploads without creating a new video on Bunny' do
      perform_job
      expect(CreateVideoOnBunny).not_to have_received(:new)
      expect(UploadVideoOnBunny).to have_received(:new).with(
        library_id: 'lib-123',
        video_id: 'existing-guid',
        video_attachment: anything
      )
    end
  end

  context 'when the stream is pending (no provider video id yet)' do
    let(:stream) do
      create(:stream, :bunny, :with_video,
        provider_video_id: nil, hls_url: nil, poster: nil, hd_url: nil, sd_url: nil)
    end

    it 'creates the video on Bunny and backfills the id and urls' do
      perform_job

      stream.reload
      expect(stream.provider_video_id).to eq 'bunny-guid-1'
      expect(stream.hls_url).to eq 'https://cdn.example.com/bunny-guid-1/playlist.m3u8'
      expect(stream.poster).to eq 'https://cdn.example.com/bunny-guid-1/thumbnail.jpg'
    end

    it 'uploads the video using the newly created provider video id' do
      perform_job
      expect(UploadVideoOnBunny).to have_received(:new).with(
        library_id: 'lib-123',
        video_id: 'bunny-guid-1',
        video_attachment: anything
      )
    end

    it 'calls the upload' do
      perform_job
      expect(upload_double).to have_received(:call)
    end

    it 'marks the upload as ready' do
      perform_job
      expect(stream.reload.upload_state).to eq 'ready'
      expect(stream.upload_error).to be_nil
    end

    context 'when the upload fails' do
      before do
        allow(UploadVideoOnBunny).to receive(:new)
          .and_raise(Video::Bunny::Error, 'Bunny HTTP 503 Service Unavailable')
      end

      it 'marks the upload as failed with the error' do
        perform_job
        expect(stream.reload.upload_state).to eq 'failed'
        expect(stream.upload_error).to include 'Bunny HTTP 503'
      end

      it 'schedules a retry' do
        expect { perform_job }
          .to have_enqueued_job(described_class).with(stream.id)
      end

      it 'persists the provider video id before the upload' do
        perform_job
        expect(stream.reload.provider_video_id).to eq 'bunny-guid-1'
      end
    end
  end

  context 'when a previous attempt created the video but failed to upload' do
    let(:stream) do
      create(:stream, :bunny, :with_video,
        provider_video_id: 'existing-guid',
        hls_url: 'https://cdn.example.com/existing-guid/playlist.m3u8',
        upload_state: 'failed',
        upload_error: 'Bunny is down')
    end

    it 'does not create a new video on Bunny' do
      perform_job
      expect(CreateVideoOnBunny).not_to have_received(:new)
    end

    it 're-uploads using the existing video id' do
      perform_job
      expect(UploadVideoOnBunny).to have_received(:new).with(
        library_id: 'lib-123',
        video_id: 'existing-guid',
        video_attachment: anything
      )
    end

    it 'marks the upload as ready on success' do
      perform_job
      expect(stream.reload.upload_state).to eq 'ready'
      expect(stream.upload_error).to be_nil
    end
  end
end
