# frozen_string_literal: true

module Video
  module Vimeo
    class Download
      FIELDS = 'download'

      def initialize(downloads)
        @downloads = downloads
      end

      def links
        # Often, two variants per quality are available. Select the best one by largest file size.
        @links ||= {
          sd: @downloads.select {|d| d['quality'] == 'sd' }.max_by {|d| d['size'] }&.fetch('link'),
          hd: @downloads.select {|d| d['quality'] == 'hd' }.max_by {|d| d['size'] }&.fetch('link'),
        }
      end

      def expires
        @expires ||= @downloads.first['expires'] if @downloads.any?
      end
    end
  end
end
