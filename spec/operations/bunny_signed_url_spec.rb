# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BunnySignedURL do
  subject(:signed_url) { described_class.new }

  let(:cdn_host) { 'vz-abc123.b-cdn.net' }
  let(:security_key) { 'super-secret' }
  let(:video_id) { 'vid-abc' }
  let(:fixed_time) { 1_700_000_000 }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('BUNNY_VIDEO_CDN_HOST', anything).and_return(cdn_host)
    allow(ENV).to receive(:fetch).with('BUNNY_STREAM_AUTHENTICATION_KEY', anything).and_return(security_key)
  end

  describe '#call' do
    before { allow(Time).to receive(:now).and_return(Time.zone.at(fixed_time)) }

    def expected_token(token_path, expires)
      raw = "#{security_key}#{token_path}#{expires}"
      Base64.strict_encode64(Digest::MD5.digest(raw)).tr('+/', '-_').delete('=')
    end

    context 'when video_id is blank' do
      it 'raises StandardError for nil' do
        expect { signed_url.call(nil) }.to raise_error(StandardError, 'video_id is required')
      end

      it 'raises StandardError for empty string' do
        expect { signed_url.call('') }.to raise_error(StandardError, 'video_id is required')
      end
    end

    it 'returns a path-based signed URL for the playlist and a query-based one for the thumbnail' do
      expires = fixed_time + BunnySignedURL::DEFAULT_EXPIRY_SECONDS
      token_path = "/#{video_id}/"
      token = expected_token(token_path, expires)
      encoded_token_path = CGI.escape(token_path)

      result = signed_url.call(video_id)

      expect(result[:video]).to eq(
        "https://#{cdn_host}/bcdn_token=#{token}&expires=#{expires}&token_path=#{encoded_token_path}#{token_path}playlist.m3u8"
      )
      expect(result[:thumbnail]).to eq(
        "https://#{cdn_host}/#{video_id}/thumbnail.jpg?token=#{token}&token_path=#{token_path}&expires=#{expires}"
      )
    end

    it 'uses the same token and expiry for both URLs' do
      result = signed_url.call(video_id)

      thumbnail_params = URI.decode_www_form(URI.parse(result[:thumbnail]).query).to_h
      video_path_segment = URI.parse(result[:video]).path

      expect(video_path_segment).to include("bcdn_token=#{thumbnail_params['token']}")
      expect(video_path_segment).to include("expires=#{thumbnail_params['expires']}")
    end

    it 'embeds the video_id directory in both the encoded token_path and the real request path' do
      result = signed_url.call(video_id)

      expect(result[:video]).to include("token_path=#{CGI.escape("/#{video_id}/")}")
      expect(result[:video]).to end_with("/#{video_id}/playlist.m3u8")
    end

    it 'accepts a custom expires_in value' do
      custom_expiry = 600
      expires = fixed_time + custom_expiry
      token_path = "/#{video_id}/"
      token = expected_token(token_path, expires)

      result = signed_url.call(video_id, expires_in: custom_expiry)

      expect(result[:video]).to include("expires=#{expires}")
      expect(result[:video]).to include("bcdn_token=#{token}")
      expect(result[:thumbnail]).to include("expires=#{expires}")
      expect(result[:thumbnail]).to include("token=#{token}")
    end
  end
end
