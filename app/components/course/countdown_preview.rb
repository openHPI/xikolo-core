# frozen_string_literal: true

module Course
  class CountdownPreview < ViewComponent::Preview
    # @!group
    def default
      render ::Course::Countdown.new(300)
    end

    def with_hours
      render ::Course::Countdown.new(2000, total_secs: 3600)
    end

    def with_days
      render ::Course::Countdown.new((2.days + 4.hours + 30.minutes).to_i)
    end

    def labeled
      render ::Course::Countdown.new((30.days + 4.hours + 30.minutes).to_i, variant: :labeled)
    end
    # @!endgroup
  end
end
