# frozen_string_literal: true

class BunnySignedURL
  DEFAULT_EXPIRY_SECONDS = 300 # 5 minutes

  def initialize
    @cdn_host = ENV.fetch('BUNNY_VIDEO_CDN_HOST', 'video.bunnycdn.com')
    @security_key = ENV.fetch('BUNNY_STREAM_AUTHENTICATION_KEY', '')
  end

  def call(video_id, expires_in: DEFAULT_EXPIRY_SECONDS)
    raise StandardError.new('video_id is required') if video_id.blank?

    expires = current_timestamp + expires_in
    token_path = "/#{video_id}/"
    token = generate_token(token_path, expires)
    # token_path must be URL-encoded when embedded in the path segment, so Bunny's
    # parser can tell where its value ends and the real file path begins.
    encoded_token_path = CGI.escape(token_path)

    video_url = "https://#{@cdn_host}/bcdn_token=#{token}&expires=#{expires}&token_path=#{encoded_token_path}#{token_path}playlist.m3u8"
    thumbnail_url = "https://#{@cdn_host}/#{video_id}/thumbnail.jpg?token=#{token}&token_path=#{token_path}&expires=#{expires}"

    {video: video_url, thumbnail: thumbnail_url}
  end

  private

  # Bunny CDN Basic Token Authentication
  # Algorithm: Base64URL(MD5(security_key + token_path + expires))
  # token_path (directory) is used as signature_path so the token covers
  # all HLS sub-requests (segments, variant playlists) under that directory.
  def generate_token(token_path, expires)
    raw = "#{@security_key}#{token_path}#{expires}"
    Base64.strict_encode64(Digest::MD5.digest(raw)).tr('+/', '-_').delete('=')
  end

  def current_timestamp
    Time.now.to_i
  end
end
