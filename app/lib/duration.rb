# frozen_string_literal: true

class Duration
  def initialize(total_seconds)
    @total_seconds = total_seconds
  end

  def hours
    @total_seconds.to_i / 3600
  end

  def minutes
    @total_seconds.to_i / 60 % 60
  end

  def seconds
    @total_seconds.to_i % 60
  end

  def to_s
    {'h' => hours, 'm' => minutes, 's' => seconds}
      .drop_while {|unit, value| value.zero? && unit != 's' }
      .map {|unit, value| "#{value}#{unit}" }
      .join(' ')
  end
end
