# frozen_string_literal: true

class Duration
  def initialize(total_seconds)
    @duration = ActiveSupport::Duration.build(total_seconds.to_i)
  end

  def hours
    @duration.in_hours.to_i
  end

  def minutes
    # Minutes remaining for an hour started.
    (@duration.in_minutes % 60).to_i
  end

  def seconds
    # Seconds remaining for a minute started.
    (@duration.in_seconds % ActiveSupport::Duration::SECONDS_PER_MINUTE).to_i
  end

  def to_s
    {'h' => hours, 'm' => minutes, 's' => seconds}
      .drop_while {|unit, value| value.zero? && unit != 's' }
      .map {|unit, value| "#{value}#{unit}" }
      .join(' ')
  end
end
