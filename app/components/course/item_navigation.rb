# frozen_string_literal: true

module Course
  class ItemNavigation < ApplicationComponent
    def initialize(items:, user:)
      @items = items
      @user = user
    end

    def accessible?(item)
      item.unlocked? || @user.allowed?('course.content.access')
    end

    def time_effort_info(item)
      sanitize(" (&sim;#{item.formatted_time_effort})") if item.with_time_effort?
    end

    private

    def render?
      true unless @in_app
    end
  end
end
