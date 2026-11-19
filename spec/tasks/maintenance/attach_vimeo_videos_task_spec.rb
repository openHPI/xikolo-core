# frozen_string_literal: true

require 'spec_helper'

describe Maintenance::AttachVimeoVideosTask do
  subject(:task) { described_class.new }

  let(:provider) { create(:video_provider, :vimeo) }
  let(:stream) { create(:stream, provider:) }

  let(:video_body) { 'FAKE_MP4_CONTENT_' * 100 }
  let(:hd_url) { 'https://vimeo.example/hd.mp4' }
  let(:sd_url) { 'https://vimeo.example/sd.mp4' }

  # A future expiration keeps `#current_downloads` from re-fetching the links
  # through the (stubbed) provider API, so the stored download URLs are used.
  let(:stream_with_downloads) do
    create(
      :stream,
      provider:,
      hd_download_url: hd_url,
      sd_download_url: sd_url,
      downloads_expire: 1.hour.from_now
    )
  end

  describe '#collection' do
    before { stream }

    it 'includes streams without an attached video' do
      expect(task.collection.pluck(:id)).to include(stream.id)
    end

    it 'is un-ordered so it can be iterated with a cursor' do
      expect(task.collection.arel.orders).to be_blank
    end

    it 'excludes streams that already have a video attached' do
      stream.video.attach(io: StringIO.new('video'), filename: 'video.mp4', content_type: 'video/mp4')

      expect(task.collection.pluck(:id)).not_to include(stream.id)
    end
  end

  describe '#process' do
    def stub_download(url, body: video_body)
      stub_request(:get, url).to_return(body:)
    end

    context 'when an HD download link is available' do
      let(:stream) { stream_with_downloads }

      before { stub_download hd_url }

      it 'attaches the HD video' do
        expect { task.process(stream) }
          .to change { stream.video.attached? }.from(false).to(true)

        expect(stream.video_blob.byte_size).to eq(video_body.bytesize)
        expect(stream.video_blob.content_type).to eq('video/mp4')
        expect(stream.video_blob.filename).to eq("#{stream.provider_video_id}.mp4")
        expect(stream.video.download).to eq(video_body)
      end
    end

    context 'when no download link is available' do
      let(:stream) do
        create(
          :stream,
          provider:,
          hd_download_url: nil,
          sd_download_url: nil,
          downloads_expire: 1.hour.from_now
        )
      end

      it 'does not attach a video and does not raise' do
        expect { task.process(stream) }.not_to raise_error

        expect(stream.video.attached?).to be false
      end
    end

    context 'when the video is no longer available on the provider' do
      before do
        allow(stream).to receive(:current_downloads)
          .and_raise(Video::Download::VideoNotAvailableError)
      end

      it 'skips the stream without attaching a video' do
        expect { task.process(stream) }.not_to raise_error

        expect(stream.video.attached?).to be false
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn)
          .with(/Skipping stream #{stream.id}.*not available/)

        task.process(stream)
      end
    end
  end
end
