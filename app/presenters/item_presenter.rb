# frozen_string_literal: true

class ItemPresenter < PrivatePresenter
  def_delegators :@item, :id, :content_id, :title,
    :published?, :unlocked?, :was_available?,
    :max_points,
    :submission_deadline,
    :submission_deadline_passed?,
    :submission_publishing_date,
    :optional, :exclude_from_recap, :position,
    :section_id, :featured, :public_description,
    :open_mode, :time_effort,
    :required_item_ids
  def_delegator :@course, :id, :course_id
  def_delegator :@course, :course_code, :course_code
  def_delegator :@course, :title, :course_title
  def_delegator :@course, :pinboard_enabled, :course_pinboard?
  def_delegator :@course, :forum_is_locked, :course_pinboard_closed?
  def_delegator :@section, :pinboard_closed, :section_pinboard_closed?
  def_delegator :@course, :lang, :lang

  class << self
    def lookup(item)
      "#{item.content_type}_item_presenter".camelize.constantize
    rescue NameError
      UnsupportedItemPresenter
    end

    def for(item, course: nil, user: nil)
      lookup(item).new(item:, course:, user:)
    end
  end

  def partial_name
    "items/#{content_type}/show_item_#{content_type}"
  end

  def redirect?
    !@redirect.nil?
  end

  def required_items
    @required_items ||= ::Course::RequiredItemPresenter.requirements_for(@item, @user)
  end

  # Children can override this to trigger an error page
  def error
    nil
  end

  def content_type
    @item['content_type']
  end

  def exercise_type
    @item['exercise_type']
  end

  def redirect(controller)
    controller.redirect_to @redirect
  end

  def layout
    'course_area_two_cols'
  end

  def show_in_side_nav?
    @item.show_in_nav && @item.published?
  end

  def to_param
    UUID(id).to_param
  end

  def path
    return if locked?

    Rails.application.routes.url_helpers.course_item_path(@course.course_code, to_param)
  end

  # Used to create human-readable labels for each course item type
  def type_label
    case content_type
      when 'quiz'
        type_label_quiz
      when 'lti_exercise'
        type_label_lti
      when 'rich_text'
        'rich_text' if @item['icon_type'].blank?
      else
        content_type
    end
  end

  def type_label_quiz
    case exercise_type
      when 'selftest'
        'self_test'
      when 'bonus'
        'bonus_test'
      when 'survey'
        'survey'
      else
        'graded_test'
    end
  end

  def type_label_lti
    case exercise_type
      when 'selftest'
        'exercise'
      when 'bonus'
        'bonus_exercise'
      else
        'graded_exercise'
    end
  end

  def label
    type_label.present? ? I18n.t("items.type_label.#{type_label}") : ''
  end

  def aria_label
    [
      title,
      type_label.present? ? I18n.t("items.type_label.#{type_label}").prepend('(').concat(')') : nil,
    ].compact.join(' ')
  end

  def item_tooltip
    item_info = [].tap do |a|
      a << I18n.t("items.type_label.#{type_label}") if type_label.present?
      a << "&sim;#{formatted_time_effort}" if with_time_effort?
    end.join(', ').tap do |s|
      s.presence&.prepend('(')&.concat(')')
    end

    {
      'item-title': title,
      'item-info': item_info,
    }.compact.to_json
  end

  def icon_class
    Course::Item::Icon.from_resource(@item).icon_class
  end

  def css_classes
    clses = [content_type]
    clses << 'visited' if visited?
    clses << 'active' if active?
    clses << 'locked' if locked?
    clses << 'optional' if optional
    clses.join ' '
  end

  def status_type
    if locked?
      'disabled'
    elsif visited?
      'filled'
    elsif optional
      'dashed'
    else
      'default'
    end
  end

  def featured_image
    # implement in subclasses
  end

  def locked_hint
    I18n.t(:'course.progress.overview.open_mode.item') if locked?
  end

  def previewing?
    # We check this, because @user can be an instance of either
    # Xikolo::Common::Auth::CurrentUser or Xikolo::Account::User
    # The latter has no allowed_any? method
    return false unless @user.respond_to?(:allowed_any?)

    @user.anonymous? || !@user.allowed_any?('course.content.access', 'course.content.access.available')
  end

  def previewable?
    item_previewable = open_mode && @item.content_type == 'video'

    # We check this, because @user can be an instance of either
    # Xikolo::Common::Auth::CurrentUser or Xikolo::Account::User
    # The latter has no allowed? method
    return item_previewable unless @user.respond_to?(:allowed?)

    item_previewable || @user.allowed?('course.content.access')
  end

  def locked?
    # If @user is an instance of Xikolo::Account::User, it has no
    # allowed? method. In this case, it is safe to assume, that the
    # item is built for a privileged user
    return !unlocked? unless @user.respond_to?(:allowed?)

    # item is generally locked for anonymous or unenrolled users, if it is not previewable
    return true unless @user&.allowed?('course.content.access.available') || previewable?

    # otherwise, the item is not locked, if it is unlocked or previewable
    !(unlocked? || previewable?)
  end

  def visited?
    (@item.user_state || 'new') != 'new'
  end

  def active?
    @active
  end

  def active!
    @active = true
  end

  def main_exercise?
    exercise_type == 'main'
  end

  def bonus_exercise?
    exercise_type == 'bonus'
  end

  def meta_tags
    {title: [@course.title, @item['title']]}
  end

  def selftest?
    exercise_type == 'selftest'
  end

  def transpipe?
    Transpipe.enabled? &&
      @user.allowed?('video.subtitle.manage') &&
      transpipe_url.present? &&
      content_type == 'video'
  end

  def transpipe_url
    @transpipe_url ||= Transpipe::URL.for_video @item
  end

  def with_time_effort?
    (@user.feature?('time_effort') && time_effort?) ||
      (@user.feature?('time_effort.video_only') &&
        time_effort? &&
        content_type == 'video')
  end

  def time_effort?
    @item.time_effort.present? && @item.time_effort > 0
  end

  def formatted_time_effort
    return unless time_effort?

    # Ceil to minutes
    minutes = (@item.time_effort.to_f / 60).ceil

    # Format time effort
    if minutes >= 60
      hours = minutes / 60
      mod_minutes = minutes % 60

      return I18n.t(:'time_effort.hours', count: hours) if mod_minutes.zero?

      return "#{I18n.t(:'time_effort.hours', count: hours)} #{I18n.t(:'time_effort.minutes', count: mod_minutes)}"
    end

    I18n.t(:'time_effort.minutes', count: minutes)
  end
end
