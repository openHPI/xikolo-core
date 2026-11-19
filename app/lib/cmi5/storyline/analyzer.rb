# frozen_string_literal: true

require 'json'

module Cmi5
  module Storyline
    # Reads the player dimensions from a Storyline package so the
    # CMI5 iframe can be sized to match.
    class Analyzer
      def initialize(cmi5_item)
        @cmi5_item = cmi5_item
      end

      def to_h
        {
          player_width: data_json.dig('display', 'width'),
          player_height: data_json.dig('display', 'height'),
        }
      end

      private

      def data_json
        @data_json ||= JSON.parse(data_script_content.presence || '{}')
      end

      def data_script_content
        attachment = @cmi5_item.data_script_file&.file
        return unless attachment&.attached?

        js = attachment.download.force_encoding(Encoding::UTF_8)

        # The dimensions live in a JSON object embedded in the JS file.
        json = js[/\{.*\}/m]

        # Undo the escaping the JS wrapper added to the JSON.
        json.gsub(/\\(['\\])/, '\1')
      end
    end
  end
end
