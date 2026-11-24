# frozen_string_literal: true

class ItemPresenter < PrivatePresenter
  def_restify_delegators :@item, :id, :content_id, :title,
    :max_points,
    :optional, :position,
    :section_id, :public_description,
    :open_mode,
    :minimum_progress_percentage,
    :required_item_ids, :published,
    :content_type, :exercise_type
  def_delegator :@course, :id, :course_id
  def_delegator :@course, :course_code, :course_code
  def_delegator :@course, :title, :course_title
  def_delegator :@course, :pinboard_enabled, :course_pinboard?
  def_delegator :@course, :forum_is_locked, :course_pinboard_closed?
  def_delegator :@course, :lang, :lang

  class << self
    # `items.content_type` stores the class name of the content resource. Each
    # supported content class has a dedicated presenter. Resolved lazily,
    # because the presenters subclass `ItemPresenter` and referencing them
    # while this class body runs would deadlock autoloading.
    def presenters
      @presenters ||= {
        'Video::Video' => VideoItemPresenter,
        'QuizService::Quiz' => QuizItemPresenter,
        'CourseService::Richtext' => RichTextItemPresenter,
        'Lti::Exercise' => LtiExerciseItemPresenter,
        'Cmi5::Item' => Cmi5ItemPresenter,
      }
    end

    def lookup(item)
      presenters.fetch(item['content_type'], UnsupportedItemPresenter)
    end

    def for(item, course: nil, user: nil)
      lookup(item).new(item:, course:, user:)
    end
  end

  def partial_name
    view_slug = self.class.name.delete_suffix('ItemPresenter').underscore
    "items/#{view_slug}/show_item_#{view_slug}"
  end

  def video?
    content_type == 'Video::Video'
  end

  def quiz?
    content_type == 'QuizService::Quiz'
  end

  def rich_text?
    content_type == 'CourseService::Richtext'
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

  def unlocked?
    ending = @item['course_archived'] ? end_date : effective_end_date

    (effective_start_date.nil? || effective_start_date <= Time.zone.now) &&
      (ending.nil? || ending >= Time.zone.now)
  end

  def redirect(controller)
    controller.redirect_to @redirect, status: :see_other
  end

  def layout
    'course_area_two_cols'
  end

  def course_info
    @course_info ||= ::CourseInfoPresenter.build(@course, @user)
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
    if quiz?
      type_label_quiz
    elsif video?
      'video'
    elsif rich_text?
      'rich_text'
    else
      'learning_material'
    end
  end

  def type_label_quiz
    case exercise_type
      when 'survey'
        'survey'
      when 'exam'
        'exam'
      else
        'learning_material'
    end
  end

  def label
    type_label.present? ? I18n.t("items.type_label.#{type_label}") : ''
  end

  def icon_class
    Course::Item::Icon.from_resource(@item).icon_class
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

  def locked_hint
    return I18n.t(:'items.exam.locked_hint', percentage: minimum_progress_percentage || 75) if exam? && exam_locked?

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
    item_previewable = open_mode && video?

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
    (@item['user_state'] || 'new') != 'new'
  end

  def main_exercise?
    exercise_type == 'main'
  end

  def exam?
    exercise_type == 'exam'
  end

  # Exams stay locked until the learner reached the required course
  # progress. Course admins (preview) and non-exam items are never locked.
  def exam_locked?
    return false unless exam?
    return false if @user.respond_to?(:allowed?) && @user.allowed?('course.content.access')
    return true if @user.respond_to?(:anonymous?) && @user.anonymous?

    course_id = @course&.id
    user_id = @user&.id
    return true if course_id.blank? || user_id.blank?

    progress = ::CourseService::CourseProgress.find_by(course_id:, user_id:)
    return true if progress.nil?

    progress.visits_percentage < (minimum_progress_percentage || 75)
  end

  def bonus_exercise?
    exercise_type == 'bonus'
  end

  def meta_tags
    {title: [@course.title, title]}
  end

  def selftest?
    exercise_type == 'selftest'
  end

  def submission_publishing_date
    DateTime.parse(@item['submission_publishing_date']) if @item['submission_publishing_date'].present?
  end

  def submission_deadline
    DateTime.parse(@item['submission_deadline']) if @item['submission_deadline'].present?
  end

  def start_date
    DateTime.parse(@item['start_date']) if @item['start_date'].present?
  end

  def end_date
    DateTime.parse(@item['end_date']) if @item['end_date'].present?
  end

  private

  def effective_start_date
    DateTime.parse(@item['effective_start_date']) if @item['effective_start_date'].present?
  end

  def effective_end_date
    DateTime.parse(@item['effective_end_date']) if @item['effective_end_date'].present?
  end
end
