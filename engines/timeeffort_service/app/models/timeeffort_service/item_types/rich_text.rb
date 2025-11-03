# frozen_string_literal: true

require 'redcarpet/render_strip'

module TimeeffortService
module ItemTypes # rubocop:disable Layout/IndentationWidth
  class RichText < Base
    attr_reader :markup

    def initialize(markup)
      super()

      @markup = markup
    end

    def time_effort
      approximate_reading_time
    end

    private

    def render_plain
      # Not the best solution for more complex markup (e.g. images),
      # but useful as base approach since most questions include
      # only text and some highlighting.
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
      markup.nil? ? '' : markdown.render(markup)
    end

    def approximate_reading_time
      word_count = render_plain.strip.tr("\n", ' ').split.size
      # Average reading speed of an adult is roughly 265 words/minute.
      # 200 words/minute used here
      # Return seconds
      ((word_count * 60).to_f / 200).ceil
    end
  end
end
end
