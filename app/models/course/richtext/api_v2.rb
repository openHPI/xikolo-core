# frozen_string_literal: true

module Course
  class Richtext
    class APIV2
      def initialize(richtext)
        @richtext = richtext
      end

      def as_json(opts = {})
        {
          id: @richtext.id,
          text: @richtext.text.external,
        }.as_json(opts)
      end
    end
  end
end
