# frozen_string_literal: true

require 'spec_helper'

describe 'Video: Playlists: Show', type: :request do
  subject(:playlist_show) { get "/playlists/#{stream.id}", params: }

  let(:params) { {} }
  let(:hls_url) { 'http://some.hls-url.com/for/master/playlist.m3u8' }
  let(:subtitle_playlist_1_url) { 'http://some.hls-url.com/for/subtitle/playlist-1.m3u8' }
  let(:subtitle_playlist_2_url) { 'http://some.hls-url.com/for/subtitle/playlist-2.m3u8' }
  let(:bandwidth_1) { 559_951 }
  let(:bandwidth_2) { 709_847 }
  let(:stream_playlist_1_url) { 'http://some.hls-url.com/for/stream/playlist-1.m3u8' }
  let(:stream_playlist_2_url) { 'http://some.hls-url.com/for/stream/playlist-2.m3u8' }
  let(:stream) { create(:stream, hls_url:) }
  let(:video) { create(:video, pip_stream: stream) }
  let(:subtitle_1) { create(:video_subtitle, video_id: video.id) }
  let(:subtitle_2) { create(:video_subtitle, video_id: video.id, lang: 'de') }

  before do
    stub_request(:get, hls_url).to_return(
      body: <<~PLAYLIST
        #EXTM3U
        #EXT-X-INDEPENDENT-SEGMENTS
        #EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",LANGUAGE="#{subtitle_1.lang}",NAME="English",AUTOSELECT=YES,DEFAULT=NO,URI="#{subtitle_playlist_1_url}",FORCED=NO
        #EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",LANGUAGE="#{subtitle_2.lang}",NAME="Deutsch",AUTOSELECT=YES,DEFAULT=NO,URI="#{subtitle_playlist_2_url}",FORCED=NO
        #EXT-X-STREAM-INF:RESOLUTION=640x360,CODECS="avc1.4D401E,mp4a.40.2",BANDWIDTH=#{bandwidth_1},SUBTITLES="subs",AVERAGE-BANDWIDTH=438000,FRAME-RATE=25.000,CLOSED-CAPTIONS=NONE
        #{stream_playlist_1_url}
        #EXT-X-STREAM-INF:RESOLUTION=640x360,CODECS="avc1.64001F,mp4a.40.2",BANDWIDTH=#{bandwidth_2},SUBTITLES="subs",AVERAGE-BANDWIDTH=574000,FRAME-RATE=25.000,CLOSED-CAPTIONS=NONE
        #{stream_playlist_2_url}
      PLAYLIST
    )
  end

  describe '(response)' do
    subject(:resp) { playlist_show; response }

    it 'returns transformed m3u8 master playlist with streams sorted by bandwidth in descending order' do
      expect(resp).to have_http_status(:ok)
      expect(resp.content_type).to eq('application/x-mpegURL')
      expect(resp.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(resp.headers['Access-Control-Allow-Headers']).to eq('Content-Type, Accept-Encoding, Range')

      playlist = M3u8::Playlist.read(resp.body)
      expect(playlist.items.count).to eq(2)
      # Sorted by bandwidth in descending order
      expect(playlist.items.first.uri).to eq("https://xikolo.de/playlists/#{stream.id}.m3u8?bandwidth=#{bandwidth_2}")
      expect(playlist.items.second.uri).to eq("https://xikolo.de/playlists/#{stream.id}.m3u8?bandwidth=#{bandwidth_1}")
      # With no subtitle references
      expect(playlist.items.first.subtitles).to be_nil
      expect(playlist.items.second.subtitles).to be_nil
    end

    it 'does not include must-revalidate in the cache control header' do
      expect(resp.cache_control).not_to include(must_revalidate: true)
    end

    context 'with embedded subtitle for video' do
      let(:params) { super().merge(embed_subtitles_for_video: video.id) }

      before { subtitle_1; subtitle_2 }

      it 'returns transformed m3u8 master playlist with replaced subtitles' do
        playlist = M3u8::Playlist.read(resp.body)
        expect(playlist.items.count).to eq(4)
        expect(playlist.items.first.uri).to eq("https://xikolo.de/playlists/#{stream.id}.m3u8?embed_subtitles_for_video=#{video.id}&subtitles=#{subtitle_1.lang}")
        expect(playlist.items.second.uri).to eq("https://xikolo.de/playlists/#{stream.id}.m3u8?embed_subtitles_for_video=#{video.id}&subtitles=#{subtitle_2.lang}")
        # Sorted by bandwidth in descending order
        expect(playlist.items.third.uri).to eq("https://xikolo.de/playlists/#{stream.id}.m3u8?bandwidth=#{bandwidth_2}")
        expect(playlist.items.fourth.uri).to eq("https://xikolo.de/playlists/#{stream.id}.m3u8?bandwidth=#{bandwidth_1}")
        # With correct subtitle group
        expect(playlist.items.first.group_id).to eq('subs')
        expect(playlist.items.second.group_id).to eq('subs')
        # With correct subtitle references
        expect(playlist.items.third.subtitles).to eq('subs')
        expect(playlist.items.fourth.subtitles).to eq('subs')
      end
    end

    context 'when trying to embed subtitles for a video without subtitles' do
      let(:params) do
        video_no_subtitles = create(:video, pip_stream: stream)
        super().merge(embed_subtitles_for_video: video_no_subtitles.id)
      end

      it 'returns the m3u8 master playlist without subtitles' do
        playlist = M3u8::Playlist.read(resp.body)
        expect(playlist.items.count).to eq(2)
        # Sorted by bandwidth in descending order
        expect(playlist.items.first.uri).to eq("https://xikolo.de/playlists/#{stream.id}.m3u8?bandwidth=#{bandwidth_2}")
        expect(playlist.items.second.uri).to eq("https://xikolo.de/playlists/#{stream.id}.m3u8?bandwidth=#{bandwidth_1}")
        # With no subtitle references
        expect(playlist.items.first.subtitles).to be_nil
        expect(playlist.items.second.subtitles).to be_nil
      end
    end

    context 'when trying to embed subtitles for an invalid video' do
      let(:params) { super().merge(embed_subtitles_for_video: 'invalid') }

      it 'returns the m3u8 master playlist without subtitles' do
        playlist = M3u8::Playlist.read(resp.body)
        expect(playlist.items.count).to eq(2)
        # Sorted by bandwidth in descending order
        expect(playlist.items.first.uri).to eq("https://xikolo.de/playlists/#{stream.id}.m3u8?bandwidth=#{bandwidth_2}")
        expect(playlist.items.second.uri).to eq("https://xikolo.de/playlists/#{stream.id}.m3u8?bandwidth=#{bandwidth_1}")
        # With no subtitles references
        expect(playlist.items.first.subtitles).to be_nil
        expect(playlist.items.second.subtitles).to be_nil
      end
    end

    context 'with bandwidth parameter' do
      let(:params) { super().merge(bandwidth: bandwidth_param) }
      let(:bandwidth_param) { bandwidth_1 }

      let!(:stream_playlist_1) do
        stub_request(:get, stream_playlist_1_url)
          .with(query: hash_including({}))
          .to_return(body: stream_playlist_body)
      end
      let!(:stream_playlist_2) do
        stub_request(:get, stream_playlist_2_url)
          .with(query: hash_including({}))
          .to_return(body: stream_playlist_body)
      end
      let(:stream_playlist_body) do
        <<~PLAYLIST
          #EXTM3U
          #EXT-X-PLAYLIST-TYPE:VOD
          #EXT-X-VERSION:3
          #EXT-X-INDEPENDENT-SEGMENTS
          #EXT-X-MEDIA-SEQUENCE:0
          #EXT-X-TARGETDURATION:7
          #EXTINF:6.0,
          #{stream_segments_base_url}/file1.ts
          #EXTINF:6.0,
          #{stream_segments_base_url}/file2.ts
          #EXT-X-ENDLIST
        PLAYLIST
      end
      let(:stream_segments_base_url) { 'http://some.cdn.content.com/for' }

      it 'returns a m3u8 stream playlist' do
        expect(resp).to have_http_status(:ok)
        expect(resp.content_type).to eq('application/x-mpegURL')
        expect(resp.headers['Access-Control-Allow-Origin']).to eq('*')
        expect(resp.headers['Access-Control-Allow-Headers']).to eq('Content-Type, Accept-Encoding, Range')

        expect(resp.body).to eq(stream_playlist_body)

        expect(stream_playlist_1).to have_been_requested
        expect(stream_playlist_2).not_to have_been_requested
      end

      context 'when the param does not match exactly' do
        let(:bandwidth_param) { bandwidth_1 + 1 }

        it 'returns a m3u8 stream playlist with the next higher bandwidth' do
          expect(resp).to have_http_status(:ok)
          expect(resp.content_type).to eq('application/x-mpegURL')
          expect(resp.headers['Access-Control-Allow-Origin']).to eq('*')
          expect(resp.headers['Access-Control-Allow-Headers']).to eq('Content-Type, Accept-Encoding, Range')

          expect(stream_playlist_1).not_to have_been_requested
          expect(stream_playlist_2).to have_been_requested
        end
      end

      context 'when the param is too high' do
        let(:bandwidth_param) { bandwidth_2 + 1 }

        it 'returns a m3u8 stream playlist with the best bandwidth' do
          expect(resp).to have_http_status(:ok)
          expect(resp.content_type).to eq('application/x-mpegURL')
          expect(resp.headers['Access-Control-Allow-Origin']).to eq('*')
          expect(resp.headers['Access-Control-Allow-Headers']).to eq('Content-Type, Accept-Encoding, Range')

          expect(stream_playlist_1).not_to have_been_requested
          expect(stream_playlist_2).to have_been_requested
        end
      end

      context 'with invalid bandwidth param' do
        let(:bandwidth_param) { 'cat' }

        it { is_expected.to have_http_status(:bad_request) }
      end

      context 'with relative URL to vtt file' do
        let(:stream_segments_base_url) { '..' }

        it 'returns a m3u8 stream playlist with an adjusted absolute URI' do
          expect(resp).to have_http_status(:ok)
          expect(resp.content_type).to eq('application/x-mpegURL')
          expect(resp.headers['Access-Control-Allow-Origin']).to eq('*')
          expect(resp.headers['Access-Control-Allow-Headers']).to eq('Content-Type, Accept-Encoding, Range')

          expect(resp.body).to eq(
            <<~PLAYLIST
              #EXTM3U
              #EXT-X-PLAYLIST-TYPE:VOD
              #EXT-X-VERSION:3
              #EXT-X-INDEPENDENT-SEGMENTS
              #EXT-X-MEDIA-SEQUENCE:0
              #EXT-X-TARGETDURATION:7
              #EXTINF:6.0,
              http://some.hls-url.com/for/file1.ts
              #EXTINF:6.0,
              http://some.hls-url.com/for/file2.ts
              #EXT-X-ENDLIST
            PLAYLIST
          )

          expect(stream_playlist_1).to have_been_requested
          expect(stream_playlist_2).not_to have_been_requested
        end
      end

      context 'with a relative URI to a Map item' do
        let(:stream_playlist_body) do
          <<~PLAYLIST
            #EXTM3U
            #EXT-X-PLAYLIST-TYPE:VOD
            #EXT-X-VERSION:6
            #EXT-X-MEDIA-SEQUENCE:0
            #EXT-X-TARGETDURATION:8
            #EXT-X-MAP:URI="#{stream_segments_base_url}/path/to/video.mp4?range=0-130"
            #EXTINF:6.0,
            #{stream_segments_base_url}/file1.ts
            #EXTINF:6.0,
            #{stream_segments_base_url}/file2.ts
            #EXT-X-ENDLIST
          PLAYLIST
        end

        it 'returns a m3u8 stream playlist with adjusted absolute URIs' do
          expect(resp).to have_http_status(:ok)
          expect(resp.content_type).to eq('application/x-mpegURL')
          expect(resp.headers['Access-Control-Allow-Origin']).to eq('*')
          expect(resp.headers['Access-Control-Allow-Headers']).to eq('Content-Type, Accept-Encoding, Range')

          expect(resp.body).to eq(
            <<~PLAYLIST
              #EXTM3U
              #EXT-X-PLAYLIST-TYPE:VOD
              #EXT-X-VERSION:6
              #EXT-X-MEDIA-SEQUENCE:0
              #EXT-X-TARGETDURATION:8
              #EXT-X-MAP:URI="http://some.cdn.content.com/for/path/to/video.mp4?range=0-130"
              #EXTINF:6.0,
              http://some.cdn.content.com/for/file1.ts
              #EXTINF:6.0,
              http://some.cdn.content.com/for/file2.ts
              #EXT-X-ENDLIST
            PLAYLIST
          )

          expect(stream_playlist_1).to have_been_requested
          expect(stream_playlist_2).not_to have_been_requested
        end
      end
    end

    context 'with subtitle parameter' do
      let(:params) { super().merge(subtitles: subtitle_param) }
      let(:subtitle_param) { subtitle_1.lang }

      let!(:subtitle_playlist_1) do
        stub_request(:get, subtitle_playlist_1_url)
      end
      let!(:subtitle_playlist_2) do
        stub_request(:get, subtitle_playlist_2_url)
      end

      it { is_expected.to have_http_status(:bad_request) }

      it 'does not request the original subtitles' do
        expect(subtitle_playlist_1).not_to have_been_requested
        expect(subtitle_playlist_2).not_to have_been_requested
      end
    end

    context 'with subtitle parameter and embedded video subtitles' do
      let(:params) { super().merge(subtitles: subtitle_param, embed_subtitles_for_video: video.id) }
      let(:subtitle_param) { subtitle_1.lang }

      let(:subtitle_playlist_body) do
        <<~PLAYLIST
          #EXTM3U
          #EXT-X-PLAYLIST-TYPE:VOD
          #EXT-X-VERSION:3
          #EXT-X-MEDIA-SEQUENCE:1
          #EXT-X-ALLOW-CACHE:NO
          #EXT-X-TARGETDURATION:#{stream.duration}
          #EXTINF:#{stream.duration},
          #{Xikolo::V2::URL.subtitle_url(subtitle_1.id)}
          #EXT-X-ENDLIST
        PLAYLIST
      end

      it 'returns a m3u8 subtitle playlist' do
        expect(resp).to have_http_status(:ok)
        expect(resp.content_type).to eq('application/x-mpegURL')
        expect(resp.headers['Access-Control-Allow-Origin']).to eq('*')
        expect(resp.headers['Access-Control-Allow-Headers']).to eq('Content-Type, Accept-Encoding, Range')
        expect(resp.body).to eq(subtitle_playlist_body)
      end

      context 'with unsupported subtitle language' do
        let(:subtitle_param) { 'xxx' }

        it 'returns a not_found error' do
          expect { resp }.to raise_error(Status::NotFound)
        end
      end
    end
  end
end
