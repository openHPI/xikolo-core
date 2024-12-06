# frozen_string_literal: true

require 'spec_helper'

describe Video::VimeoAdapter do
  let(:provider) { create(:video_provider, :vimeo) }
  let(:headers) do
    {
      'Authorization' => "Bearer #{provider.credentials['token']}",
      'Accept' => 'application/vnd.vimeo.*+json;version=3.4',
    }
  end

  describe '#sync' do
    subject(:sync_provider) { provider.sync }

    let(:videos_url) do
      uri = Addressable::Template.new \
        'https://api.vimeo.com/me/videos{?fields,page,sort}'

      uri = uri.partial_expand \
        sort: 'modified_time',
        fields: %w[
          uri
          name
          duration
          width
          height
          status
          modified_time
          pictures.sizes.link
          pictures.sizes.width
          files.quality
          files.size
          files.md5
          files.link
          download
        ]

      ->(**kwargs) { uri.expand(kwargs) }
    end

    let!(:page1) do
      stub_request(:get, videos_url.call.to_s)
        .with(headers:)
        .to_return(body: page1_response)
    end

    let(:page1_response) do
      File.read 'spec/support/files/video/vimeo/videos/1.json'
    end

    let!(:page2) do
      stub_request(:get, videos_url.call(page: 2).to_s)
        .with(headers: headers.merge('Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3'))
        .to_return(body: File.read('spec/support/files/video/vimeo/videos/2.json'))
    end

    let!(:page3) do
      stub_request(:get, videos_url.call(page: 3).to_s)
        .with(headers:)
        .to_return(body: File.read('spec/support/files/video/vimeo/videos/3.json'))
    end

    context 'with authentication error' do
      let!(:page1) do
        stub_request(:get, videos_url.call.to_s)
          .with(headers:)
          .to_return(status: 401)
      end

      it 'raises a domain-specific error' do
        expect { sync_provider }.to raise_error Video::Provider::AuthenticationFailed
        expect(page1).to have_been_requested.once
      end
    end

    it 'calls the Vimeo API' do
      sync_provider
      expect(page1).to have_been_requested.once
      expect(page2).to have_been_requested.once
      expect(page3).to have_been_requested.once
    end

    it 'chooses the larger one out of two SD streams in a Vimeo video resource' do
      sync_provider
      expect(Video::Stream.find_by(provider_video_id: '124597457').sd_size).to eq 250
    end

    it 'chooses the largest download URL both for SD and HD in a Vimeo video resource' do
      sync_provider

      stream = Video::Stream.find_by(provider_video_id: '124597457')
      expect(stream.sd_download_url).to eq 'https://download.vimeo.com/larger.sd.mp4'
      expect(stream.hd_download_url).to eq 'https://download.vimeo.com/larger.hd.mp4'
    end

    context 'without any data' do
      let(:page1_response) do
        File.read 'spec/support/files/video/vimeo/videos/no_data.json'
      end

      it 'raises' do
        # TODO: https://openhpi.sentry.io/issues/5730594724
        expect { sync_provider }.to raise_error KeyError
      end
    end

    context 'without downloads in response' do
      let(:page1_response) do
        File.read 'spec/support/files/video/vimeo/videos/no_downloads.json'
      end

      it 'creates a stream' do
        expect { sync_provider }.to change(Video::Stream, :count).from(0).to(1)
      end
    end

    context 'without an expiration date for downloads' do
      let(:page1_response) do
        File.read 'spec/support/files/video/vimeo/videos/no_expiration.json'
      end

      it 'creates a stream' do
        expect { sync_provider }.to change(Video::Stream, :count).from(0).to(1)
      end
    end

    context 'with a synchronized_at date' do
      let(:sync_date) do
        # A date between before last item on page 2
        Time.iso8601('2017-10-15T16:00:00+02:00')
      end

      before { provider.update! synchronized_at: sync_date }

      it 'stops iteration before page 3' do
        sync_provider
        expect(page1).to have_been_requested.once
        expect(page2).to have_been_requested.once
        expect(page3).not_to have_been_requested
      end

      it 'updates synchronized_at' do
        Timecop.freeze do
          # Force microsecond precision instead of nanoseconds
          time = Time.iso8601 Time.zone.now.iso8601(6)

          expect do
            sync_provider
          end.to change {
            provider.reload.synchronized_at
          }.from(sync_date).to(time)
        end
      end
    end
  end

  describe '#attach_subtitles!' do
    subject(:attach_subtitles) { provider.attach_subtitles!(stream, subtitle) }

    let(:stream) { create(:stream, provider:) }
    let(:subtitle) { create(:video_subtitle, :with_cues) }
    let(:tracks_uri) { "https://api.vimeo.com/videos/#{stream.provider_video_id}/texttracks" }
    let(:response) do
      {
        metadata: {
          connections: {
            texttracks: {
              uri: tracks_uri,
            },
          },
        },
      }.to_json
    end

    let(:get_videos_stub) do
      stub_request(:get, "https://api.vimeo.com/videos/#{stream.provider_video_id}")
        .with(
          headers:,
          query: {fields: 'metadata.connections.texttracks.uri'}
        ).to_return(body: response)
    end

    let(:create_track_stub) do
      stub_request(:post, tracks_uri)
        .with(
          body: {language: 'en', type: 'subtitles'},
          headers:
        ).to_return(body: {'link' => tracks_uri, 'uri' => tracks_uri}.to_json)
    end

    let(:store_content_stub) do
      stub_request(:put, tracks_uri)
        .with(
          body: subtitle.to_vtt,
          headers:
        ).to_return(status: 200)
    end

    let(:mark_track_active_stub) do
      stub_request(:patch, tracks_uri)
        .with(
          body: {active: true},
          headers:
        ).to_return(body: {status: 200}.to_json)
    end

    before do
      get_videos_stub
      create_track_stub
      store_content_stub
      mark_track_active_stub
    end

    it 'syncs subtitles with Vimeo' do
      expect { attach_subtitles }.not_to raise_error

      expect(create_track_stub).to have_been_requested
      expect(store_content_stub).to have_been_requested
      expect(mark_track_active_stub).to have_been_requested
    end
  end
end
