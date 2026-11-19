# frozen_string_literal: true

module Course
  # Everything but the course details is locked until the user is enrolled.
  class Navigation < ApplicationComponent
    # @param active [Symbol] the page the user is on: :details, :forum, :progress, :recap, or :announcements
    # @param locked [Boolean] locks everything but the course details, e.g. until the user is enrolled
    # @param forum [Boolean] whether the course has the forum enabled
    # @param recap_url [String, nil] adds the quiz recap tab when given
    # @param unread_announcements [Integer] shown as a badge on the announcements button
    def initialize(course_code:, active:, locked: false, forum: true, recap_url: nil, unread_announcements: 0)
      @course_code = course_code
      @active = active
      @locked = locked
      @forum = forum
      @recap_url = recap_url
      @unread_announcements = unread_announcements
    end

    private

    def tabs
      [
        tab(:details, course_path(@course_code), icon: 'info', locked: false),
        (tab(:forum, course_pinboard_index_path(@course_code), icon: 'comment-text') if @forum),
        tab(:progress, course_progress_path(@course_code), icon: 'check'),
        (tab(:recap, @recap_url, icon: 'lightbulb') if @recap_url),
      ].compact
    end

    def tab(name, url, icon:, locked: @locked)
      {
        url:,
        label: t(:"components.course_navigation.#{name}.label"),
        description: t(:"components.course_navigation.#{name}.description"),
        icon: locked ? 'lock' : icon,
        locked:,
        active: @active == name,
      }
    end

    def announcements_url
      course_announcements_path(@course_code)
    end

    # On the announcements page itself, they are being read.
    def unread_announcements?
      @unread_announcements.positive? && !announcements_active?
    end

    def announcements_active?
      @active == :announcements
    end
  end
end
