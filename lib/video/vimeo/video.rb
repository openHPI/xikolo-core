# frozen_string_literal: true

module Video
  module Vimeo
    class Video
      FIELDS = %w[
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
      ].join(',').freeze

      def initialize(json)
        @json = json
      end

      def modified_time
        Time.iso8601 @json.fetch('modified_time')
      end

      # Response structure:
      # "uri": "/videos/124929796:7be25ea5f6"
      def id
        %r{^/videos/(?<id>.+)$}.match(@json.fetch('uri'))[:id]
      end

      # Extract required information from the JSON API response
      def to_hash
        {
          provider_video_id: id,
          title: @json.fetch('name'),
          height: @json.fetch('height'),
          width: @json.fetch('width'),
          duration: @json.fetch('duration'),
          poster:,
          hd_url: urls[:hd],
          hd_size: sizes[:hd],
          hd_md5: urls[:hd_md5],
          hd_download_url: download.links[:hd],
          sd_url: urls[:sd],
          sd_size: sizes[:sd],
          sd_md5: urls[:sd_md5],
          sd_download_url: download.links[:sd],
          hls_url: urls[:hls],
          hls_size: sizes[:hls],
          hls_md5: urls[:hls_md5],
          downloads_expire: download.expires,
        }
      end

      private

      def poster
        @json.dig('pictures', 'sizes').to_a
          .tap {|sizes| return nil if sizes.empty? }
          .max_by {|p| p['width'].to_i }
          .fetch('link')
      end

      def urls
        @urls ||= {
          sd: files[:sd]&.fetch('link'),
          sd_md5: files[:sd]&.fetch('md5'),
          hd: files[:hd]&.fetch('link'),
          hd_md5: files[:hd]&.fetch('md5'),
          hls: files[:hls]&.fetch('link'),
          hls_md5: files[:hls]&.fetch('md5'),
        }
      end

      def sizes
        @sizes ||= files.transform_values {|f| f&.fetch('size') }
      end

      def files
        @files ||= begin
          files = @json.fetch('files')

          # multiple sd qualities, select best one by largest file size
          {
            sd: files.select {|f| f['quality'] == 'sd' }.max_by {|f| f['size'] },
            hd: files.find {|f| f['quality'] == 'hd' },
            hls: files.find {|f| f['quality'] == 'hls' },
          }
        end
      end

      def download
        @download ||= Vimeo::Download.new(@json.fetch('download', []))
      end
    end
  end
end
