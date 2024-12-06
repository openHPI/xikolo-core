# frozen_string_literal: true

module Video
  class SubtitleCue
    class APIV2
      def initialize(cue)
        @cue = cue
      end

      def as_json(opts = {})
        {
          id:,
          track_id:,
          identifier: @cue.identifier,
          start:,
          stop:,
          text: @cue.text,
          settings: @cue.settings,
        }.as_json(opts)
      end

      private

      def id
        Digest::MD5.hexdigest("#{track_id}|#{start}|#{stop}")
      end

      def track_id
        @cue.subtitle_id
      end

      def start
        @cue.formatted_start
      end

      def stop
        @cue.formatted_stop
      end
    end
  end
end
