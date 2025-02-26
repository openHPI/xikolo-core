# frozen_string_literal: true

module Util
  class RelativeTimeTagPreview < ViewComponent::Preview
    # @!group
    # Displays a relative timestamp for a past date (e.g., "3 days ago").
    def past
      render Util::RelativeTimeTag.new(3.days.ago)
    end

    # Displays an absolute date when the event occurred more than 4 days ago (e.g., "March 15, 2014").
    def past_default_limit_reached
      render Util::RelativeTimeTag.new(10.years.ago)
    end

    # Displays a relative timestamp for a future date (e.g., "tomorrow").
    def future
      render Util::RelativeTimeTag.new(1.day.from_now)
    end

    # Displays an absolute date when the event is more than 4 days away (e.g., "on Feb 24, 2030").
    def future_default_limit_reached
      render Util::RelativeTimeTag.new(5.years.from_now)
    end

    # Displays an absolute date when the event occurred more time ago than configured
    def past_with_limit_configured
      render Util::RelativeTimeTag.new(3.days.ago, limit: 'P1D')
    end

    # Displays an absolute date when the event is more time away than configured
    def future_with_limit_configured
      render Util::RelativeTimeTag.new(3.days.from_now, limit: 'P1D')
    end
    # @!endgroup
  end
end
