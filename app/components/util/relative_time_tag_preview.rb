# frozen_string_literal: true

module Util
  class RelativeTimeTagPreview < ViewComponent::Preview
    # @!group

    # @label Past, relative date: 'x days ago'
    def past
      render Util::RelativeTimeTag.new(3.days.ago)
    end

    # @label Past, absolute date
    def past_limit_reached
      render Util::RelativeTimeTag.new(10.years.ago)
    end

    # @label Future, relative date: 'x day from now'
    def future
      render Util::RelativeTimeTag.new(1.day.from_now)
    end

    # @label Future, absolute date
    def future_limit_reached
      render Util::RelativeTimeTag.new(5.years.from_now)
    end

    # @label Past, with a limit showing absolute date
    def past_with_limit_configured
      render Util::RelativeTimeTag.new(3.days.ago, limit: 1.day.ago)
    end

    # @label Future, with a limit showing absolute date
    def future_with_limit_configured
      render Util::RelativeTimeTag.new(3.days.from_now, limit: 1.day.ago)
    end
    # @!endgroup
  end
end
