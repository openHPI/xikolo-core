# frozen_string_literal: true

class Account::PreferencesPresenter
  class << self
    def notification(name, opts = {})
      notifications[name] = opts
    end

    def notifications
      @notifications ||= {}
    end
  end

  notification 'news.announcement'
  notification 'course.announcement'
  notification 'pinboard.new_answer'

  notification 'stats', platform: false, teacher: true

  def initialize(preferences)
    @preferences = preferences
  end

  def notifications_enabled?
    @preferences.get_bool 'notification.email.global', default: true
  end

  def hide_notification_preferences?
    !notifications_enabled?
  end

  def get(key)
    PreferencePresenter.new @preferences, key
  end

  def notifications
    self.class.notifications.reject do |_, opts|
      opts[:teacher]
    end.map do |name, opts|
      NotificationPresenter.new @preferences, name, opts
    end
  end

  def teacher_notifications
    self.class.notifications.select do |_, opts|
      opts[:teacher]
    end.map do |name, opts|
      NotificationPresenter.new @preferences, name, opts
    end
  end

  class PreferencePresenter < ActionView::Base
    attr_reader :key, :label, :id, :default

    def initialize(preferences, key, opts = {})
      super(nil, {}, nil)

      @preferences = preferences
      @key = key
      @default = opts.fetch(:default, true)
      @label = t(:"account.preferences.show.#{key}")
      @id = "preferences-#{key.tr('^A-Za-z0-9', '-')}"
    end

    def value
      @preferences.get_bool key, default:
    end

    def render_label(opts = {})
      label = opts.fetch(:label, self.label)
      id = opts.fetch(:id, self.id)

      tag.label(label, **opts, for: id)
    end

    def render_switch(opts = {})
      data = opts.fetch(:data, {})
      id = opts.fetch(:id, self.id)
      value = opts.fetch(:value) { self.value }
      size = opts.fetch(:size, nil)
      key = opts.fetch(:key, self.key)
      switch_css = 'toggle-switch'

      switch_css += "-#{size}" if size

      opts = opts.merge(class: [switch_css, opts[:class]].flatten.join(' ').strip,
        id:,
        data:)

      check_box_tag(key, value, value, opts) +
        tag.label('', for: id)
    end

    def render(opts = {})
      render_label(opts) + render_switch(opts)
    end
  end

  class NotificationPresenter < PreferencePresenter
    attr_reader :name, :platform, :teacher, :platform_key

    def initialize(preferences, name, opts = {})
      super(preferences, "notification.email.#{name}", opts)

      @name = name
      @platform = opts.fetch(:platform, true)
      @teacher = opts.fetch(:teacher, false)

      @platform_key = "notification.platform.#{name}"
      @platform_id = "preferences-#{@platform_key.tr('^A-Za-z0-9', '-')}" if @platform
    end

    def value(scope = nil)
      if scope == :platform
        @preferences.get_bool(platform_key, default:)
      else
        super()
      end
    end

    def render_switch(scope, opts = {})
      return if (scope == :platform) && !platform

      opts.reverse_merge!(
        key: (scope == :platform ? platform_key : key),
        value: value(scope)
      )

      opts.reverse_merge! id: @platform_id if scope == :platform

      super(opts)
    end
  end
end
