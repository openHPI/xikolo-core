# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UploadVideoToBunnyJob, type: :job do
  subject(:perform_job) { described_class.perform_now(short.id) }

  let(:short) { create(:'course_service/short', :with_video) }
  let(:create_double) { instance_double(CreateVideoOnBunny, call: 'new-video-guid') }
  let(:upload_double) { instance_double(UploadVideoOnBunny, call: nil) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('BUNNY_VIDEO_LIBRARY_ID').and_return('lib-123')
    allow(CreateVideoOnBunny).to receive(:new).and_return(create_double)
    allow(UploadVideoOnBunny).to receive(:new).and_return(upload_double)
  end

  context 'when the short has no video' do
    let(:short) { create(:'course_service/short') }

    it 'does not create a video on Bunny' do
      perform_job
      expect(CreateVideoOnBunny).not_to have_received(:new)
    end

    it 'does not upload a video' do
      perform_job
      expect(UploadVideoOnBunny).not_to have_received(:new)
    end
  end

  context 'when the short has no bunny_video_id' do
    it 'creates a video on Bunny' do
      perform_job
      expect(CreateVideoOnBunny).to have_received(:new).with(library_id: 'lib-123', title: short.title)
    end

    it 'saves the returned video id on the short' do
      expect { perform_job }.to change { short.reload.bunny_video_id }.from(nil).to('new-video-guid')
    end

    it 'uploads the video' do
      perform_job
      expect(UploadVideoOnBunny).to have_received(:new).with(
        library_id: 'lib-123',
        video_id: 'new-video-guid',
        video_attachment: anything
      )
    end
  end

  context 'when the short already has a bunny_video_id' do
    let(:short) { create(:'course_service/short', :with_video, bunny_video_id: 'existing-guid') }

    it 'does not create a new video on Bunny' do
      perform_job
      expect(CreateVideoOnBunny).not_to have_received(:new)
    end

    it 'uploads using the existing video id' do
      perform_job
      expect(UploadVideoOnBunny).to have_received(:new).with(
        library_id: 'lib-123',
        video_id: 'existing-guid',
        video_attachment: anything
      )
    end
  end

  context 'when the upload fails' do
    before do
      allow(UploadVideoOnBunny).to receive(:new)
        .and_raise(Video::Bunny::Error, 'Bunny HTTP 503 Service Unavailable')
    end

    it 'saves the provider video id before the upload' do
      perform_job
      expect(short.reload.bunny_video_id).to eq 'new-video-guid'
    end

    it 'schedules a retry' do
      expect { perform_job }
        .to have_enqueued_job(described_class).with(short.id)
    end
  end

  context 'when a previous attempt created the video but failed to upload' do
    let(:short) { create(:'course_service/short', :with_video, bunny_video_id: 'existing-guid') }

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
  end
end
