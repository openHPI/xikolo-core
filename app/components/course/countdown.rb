# frozen_string_literal: true

module Course
  class Countdown < ApplicationComponent
    Unit = Data.define(:name, :value)

    # @param total_secs [Integer, nil] the full duration. Decides whether days
    #   and hours are shown, so the layout does not change while counting down.
    # @param form [String, nil] selector of a form to submit when the time is up
    # @param variant [Symbol] `:default` shows the time inline, e.g. 01:23:45
    #   for a quiz time limit. `:labeled` shows large digits with a unit label
    #   below each, down to minutes, e.g. until a course starts.
    def initialize(remaining_secs, total_secs: nil, form: nil, variant: :default)
      @remaining_secs = remaining_secs
      @total_secs = total_secs
      @form = form
      @variant = variant
    end

    def labeled?
      @variant == :labeled
    end

    def units
      @units ||= [
        (Unit.new(name: 'days', value: days) if with_days?),
        (Unit.new(name: 'hours', value: hours) if with_hours?),
        Unit.new(name: 'minutes', value: minutes),
        (Unit.new(name: 'seconds', value: seconds) unless labeled?),
      ].compact
    end

    def unit_label(unit, count)
      t("components.countdown.units.#{unit}", count:)
    end

    # The countdown needs at least two digits, more for long waits.
    def digits(value)
      [value.to_s.length, 2].max
    end

    def pad(value)
      value.to_s.rjust(2, '0')
    end

    private

    def duration
      @total_secs || @remaining_secs
    end

    def with_days?
      duration >= 86_400
    end

    def with_hours?
      with_days? || duration >= 3600
    end

    def days
      @remaining_secs / 86_400
    end

    def hours
      with_days? ? (@remaining_secs % 86_400) / 3600 : @remaining_secs / 3600
    end

    def minutes
      (@remaining_secs % 3600) / 60
    end

    def seconds
      @remaining_secs % 60
    end
  end
end
