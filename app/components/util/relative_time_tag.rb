# frozen_string_literal: true

module Util
  class RelativeTimeTag < ApplicationComponent
    # Generates a relative-time HTML element using a given timestamp.
    #
    # @param time [Time] The timestamp to display.
    # @param limit [String] An ISO 8601 duration (e.g., "P4D" for 4 days, "PT3H" for 3 hours).
    #
    def initialize(time, limit: 'P4D')
      @time = time.iso8601
      @limit = limit
    end

    def call
      tag.relative_time(datetime: @time, threshold: @limit)
    end
  end
end
