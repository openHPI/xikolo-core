# frozen_string_literal: true

module Util
  class RelativeTimeTag < ApplicationComponent
    def initialize(time, limit: 4.days.ago)
      @time = time.iso8601
      @limit = limit.iso8601
    end

    def call
      # For progressive enhancement,
      # the component displays the unformatted time until JS converts it.
      tag.time(@time, datetime: @time, data: {controller: 'relative-time', time: @time, limit: @limit})
    end
  end
end
