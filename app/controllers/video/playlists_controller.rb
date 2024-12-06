# frozen_string_literal: true

class Video::PlaylistsController < ApplicationController
  before_action :ensure_valid_bandwidth
  before_action :ensure_valid_subtitles

  def show
    # By default, Rails uses "max-age=0, private, must-revalidate" as the value
    # for the "Cache-Control" header. Especially using "must-revalidate" results
    # in the problem that for downloaded videos on iOS, the playback will not
    # start if no Internet connection is given. Despite the lack of access to
    # the Internet, the HLS playback framework on iOS tries to revalidate the
    # provided URLs and remains in a loading state ignoring the previously
    # downloaded data (see https://forums.developer.apple.com/thread/117784).
    # Hence, we are using a more reasonable value.
    response.headers['Cache-Control'] = "max-age=#{1.hour}, public"

    # Required CORS header to support Google Cast and other web-based HLS video
    # players. Since streaming protocols, unlike most file based protocols,
    # access content in an asynchronous way using XMLHTTPRequest, they are
    # guarded against inappropriate access by the CORS header from the server
    # where the resource originates. Since we do not know exactly which domains
    # from Google access the streams, we use a wildcard. Vimeo provides the same
    # header and value for its master playlists which we manipulate here.
    response.headers['Access-Control-Allow-Origin'] = '*'

    # The Access-Control-Allow-Headers response header is used in response to a
    # preflight request which includes the Access-Control-Request-Headers to
    # indicate which HTTP headers can be used during the actual request. Google
    # says it also needs Content-Type, Accept-Encoding, and Range. Vimeo
    # provides the header Access-Control-Allow-Headers for the master playlist,
    # probably to tell the client that it supports these headers for the
    # embedded streams. Therefore, we mirror Vimeo's behavior since we also
    # embed the Vimeo streams that, as it seems, support these.
    response.headers['Access-Control-Allow-Headers'] = %w[
      Content-Type
      Accept-Encoding
      Range
    ].join(', ')

    # The MIME type for HTTP Live Streaming (HLS).
    response.headers['Content-Type'] = 'application/x-mpegURL'

    render plain: playlist
  end

  private

  def bandwidth
    return if params[:bandwidth].blank?

    params[:bandwidth].to_i
  end

  def subtitle_language
    params[:subtitles]
  end

  def ensure_valid_bandwidth
    return unless bandwidth
    return if bandwidth.positive?

    render json: nil, status: :bad_request
  end

  def ensure_valid_subtitles
    return unless subtitle_language
    return if video.present?

    render json: nil, status: :bad_request
  end

  def playlist
    if bandwidth
      transformed_stream_playlist
    elsif subtitle_language
      xikolo_subtitle_playlist
    else
      transformed_master_playlist
    end
  end

  def transformed_master_playlist
    M3u8Playlist
      .from(stream, video:, playlist_id: params[:id])
      .master_playlist
  end

  def transformed_stream_playlist
    M3u8Playlist
      .from(stream, bandwidth:)
      .stream_playlist
  end

  def xikolo_subtitle_playlist
    subtitle = video.subtitles.find_by(lang: subtitle_language)

    raise Status::NotFound if subtitle.nil?

    M3u8Playlist
      .for(subtitle_id: subtitle.id, duration: video.duration)
      .subtitle_playlist
  end

  def video_id
    params[:embed_subtitles_for_video]
  end

  def video
    @video ||= begin
      Video::Video.find(video_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end

  def stream
    @stream ||= Video::Stream.find(params.require(:id))
  end
end
