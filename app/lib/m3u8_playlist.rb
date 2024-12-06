# frozen_string_literal: true

require 'uri'

class M3u8Playlist
  class << self
    def from(stream = nil, opts = {})
      new(stream, opts)
    end

    def for(opts = {})
      # This playlist is not created from another playlist and therefore does
      # not require a stream input. #subtitle_playlist creates a new playlist
      # from the given opts.
      new(nil, opts)
    end
  end

  def initialize(stream, opts)
    @playlist = if stream.present?
                  M3u8::Playlist.read(
                    Restify.new(stream.hls_url).get.value!
                  )
                end
    @opts = opts
  end
  SUBTITLE_GROUP = 'subs' # Place all of our subtitles in a single group
  def master_playlist
    # Replace URIs of subtitles and stream playlist items to point to this
    # controller. If there was a video explicitly specified for the subtitles,
    # use the subtitles of the video instead of the subtitles from the
    # original HLS playlist.
    #
    # Order of stream playlist items:
    # When this master playlist is processed by the iOS frameworks for HLS
    # playback, the order of the provided stream playlist items matters.
    # It's best practice to sort the stream playlist items by bandwidth in
    # descending order to support the HLS playback framework on iOS in
    # choosing the right quality level. This approach was discussed in the
    # following WWDC session in 2016
    # (https://developer.apple.com/videos/play/wwdc2016/503 @ 33:15). As the
    # stream playlist items appear to ordered  by ascending bandwidth size in
    # the HLS master playlist we receive from Vimeo (not deterministic),
    # we have to sort the stream playlist items ourselves.
    @playlist.tap do |playlist|
      subtitle_playlist_items = []
      stream_playlist_items = []

      playlist.items.each do |item|
        if item.is_a?(M3u8::MediaItem) && item.type == 'SUBTITLES'
          subtitle_playlist_items << item
        elsif item.is_a?(M3u8::PlaylistItem)
          item.uri = Xikolo::V2::URL.playlist_url(
            id: @opts.fetch(:playlist_id),
            format: 'm3u8',
            bandwidth: item.bandwidth
          )
          stream_playlist_items << item
        end
      end

      # Remove the existing subtitles and their references
      playlist.items -= subtitle_playlist_items
      stream_playlist_items.each {|item| item.subtitles = nil }

      # If there is a video item for the subtitles specified and subtitles exist
      if @opts.fetch(:video).present? && subtitle_media_items.any?
        # Add our own subtitles
        playlist.items += subtitle_media_items

        # Apply the subtitle group to the stream playlist items
        stream_playlist_items.each {|item| item.subtitles = SUBTITLE_GROUP }
      end

      # Remove and re-add stream playlist items in correct order
      playlist.items -= stream_playlist_items
      playlist.items += stream_playlist_items.sort_by(&:bandwidth).reverse
    end
  end

  def stream_playlist
    # Retrieve corresponding stream playlist for selected bandwidth and
    # make relative URI absolute.
    source = if matching_stream_playlist&.uri.present?
               Restify.new(matching_stream_playlist.uri).get.value!.response.body
             else
               '' # Return an empty playlist source
             end

    M3u8::Playlist.read(source).tap do |playlist|
      playlist.items.each do |item|
        if item.is_a?(M3u8::SegmentItem)
          item.segment = absolute_uri(item.segment)
        end

        if item.is_a?(M3u8::MapItem)
          item.uri = absolute_uri(item.uri)
        end
      end
    end
  end

  def subtitle_playlist
    M3u8::Playlist.new(
      type: 'VOD',
      version: 3,
      sequence: 1,
      cache: false,
      target: @opts.fetch(:duration)
    ).tap do |playlist|
      playlist.items = [M3u8::SegmentItem.new(
        duration: @opts.fetch(:duration),
        segment: Xikolo::V2::URL.subtitle_url(@opts.fetch(:subtitle_id))
      )]
    end
  end

  private

  def video_subtitles
    @opts.fetch(:video).subtitles
  end

  def video_id
    @opts.fetch(:video).id
  end

  def subtitle_media_items
    @subtitle_media_items ||= video_subtitles.map do |subtitle|
      uri = Xikolo::V2::URL.playlist_url(
        id: @opts.fetch(:playlist_id),
        format: 'm3u8',
        subtitles: subtitle.lang,
        embed_subtitles_for_video: video_id
      )
      language_name = I18n.t(
        "languages.name.#{subtitle.lang}",
        default: subtitle.lang
      )

      M3u8::MediaItem.new(
        type: 'SUBTITLES',
        group_id: SUBTITLE_GROUP,
        language: subtitle.lang,
        name: language_name, # Required for playback in Safari.
        autoselect: true, # A video player might preselect this option.
        default: false, # This option does not have to be preselected.
        uri:
      )
    end
  end

  def matching_stream_playlist
    return @stream_playlist if @stream_playlist

    stream_playlists = @playlist.items.select do |item|
      item.is_a?(M3u8::PlaylistItem)
    end

    # Sort the sub-playlists by their bandwidth
    by_bandwidth = stream_playlists.sort_by(&:bandwidth)

    # If there are sub-playlists with a matching (exact or better) bandwidth,
    # take the lowest (best matching) bandwidth. Otherwise, take the
    # sub-playlist with the best provided bandwidth.
    @stream_playlist = by_bandwidth.detect(-> { by_bandwidth.last }) do |sub|
      sub.bandwidth >= @opts.fetch(:bandwidth)
    end
  end

  def absolute_uri(segment_uri)
    # If the URI for the segment is already absolute, use it.
    return segment_uri if URI(segment_uri).absolute?

    # Otherwise, resolve the relative URI against the base URI.
    URI.join(matching_stream_playlist.uri, segment_uri)
  end
end
