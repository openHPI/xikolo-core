# frozen_string_literal: true

module Video
  module SubtitleTrack
    class APIV2
      def initialize(subtitle)
        @subtitle = subtitle
      end

      def as_json(opts = {})
        {
          id: @subtitle.id,
          language: @subtitle.lang,
          automatic: @subtitle.automatic,
        }.as_json(opts)
      end
    end
  end
end
