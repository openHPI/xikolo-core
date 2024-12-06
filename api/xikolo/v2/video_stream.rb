# frozen_string_literal: true

module Xikolo
  module V2
    class VideoStream
      class << self
        def schema
          {
            hd_url: :string,
            sd_url: :string,
            hls_url: :string,
            hd_size: :integer,
            sd_size: :integer,
            thumbnail_url: :string,
          }
        end

        def data(stream, video_id = nil)
          {
            hd_url: stream.hd_url,
            sd_url: stream.sd_url,
            hls_url: stream.hls_url.present? ? Xikolo::V2::URL.playlist_url(id: stream.id, format: 'm3u8', embed_subtitles_for_video: video_id) : nil,
            hd_size: stream.hd_size || 0,
            sd_size: stream.sd_size || 0,
            thumbnail_url: stream.poster,
          }
        end
      end
    end
  end
end
