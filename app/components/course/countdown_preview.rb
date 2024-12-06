# frozen_string_literal: true

module Course
  class CountdownPreview < ViewComponent::Preview
    # @!group
    def default
      render ::Course::Countdown.new(300)
    end

    def already_started
      render ::Course::Countdown.new(2000, total_secs: 3600)
    end
    # @!endgroup
  end
end
