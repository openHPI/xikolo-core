# frozen_string_literal: true

module Course
  class Countdown < ApplicationComponent
    def initialize(remaining_secs, total_secs: nil, form: nil)
      @remaining_secs = remaining_secs
      @total_secs = total_secs
      @form = form
    end

    def format_with_hours?
      (@total_secs || @remaining_secs) >= 3600
    end

    def format_time
      seconds = Time.zone.at(@remaining_secs)
      format_with_hours? ? seconds.strftime('%H:%M:%S') : seconds.strftime('%M:%S')
    end
  end
end
