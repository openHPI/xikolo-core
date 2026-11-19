# frozen_string_literal: true

class CourseInfoPresenter < PrivatePresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::AssetUrlHelper
  include MarkdownHelper

  def_restify_delegators :@course, :id,
    :course_code,
    :title,
    :abstract,
    :available?,
    :was_available?,
    :lang,
    :classifiers,
    :alternative_teacher_text,
    :external_course_url,
    :status,
    :pinboard_enabled,
    :learning_goals,
    :course_format,
    :updated_at

  def self.build(course, user, enrollments = nil)
    new(course:, user:, enrollments:)
  end

  def start_date
    return if @course.start_date.blank?

    @course.start_date
  end

  def end_date
    return if @course.end_date.blank?

    @course.end_date
  end

  def display_start_date
    return if @course.display_start_date.blank?

    @course.display_start_date
  end

  def effective_start_date
    display_start_date || start_date
  end

  def visual?
    visual&.image_url
  end

  def visual_url
    visual&.image_url.presence || ActionController::Base.helpers.asset_url('defaults/course.png')
  end

  def abstract_html
    render_markdown @course['abstract']
  end

  def description_markup
    @course['description']
  end

  def description_html(external: false)
    desc = render_markdown(externalize_description, allow_tables: true, escape_html: false)
    if external && desc
      desc.gsub %r{(/files/[a-z0-9-]+)} do |match|
        Xikolo.config.base_url.join(match).to_s
      end
    else
      desc
    end
  end

  def learning_goals?
    learning_goals.present?
  end

  def channel_code
    @course.attributes['channel_code']
  end

  def date_label
    return unless Xikolo.config.course_details['show_date_label']

    if end_date&.past?
      return I18n.t(:'course.courses.date.self_paced_since',
        date: I18n.l(@course.end_date, format: :short_datetime))
    end

    if end_date.blank?
      return date_label_with_no_end_date
    end

    if display_start_date.present? && end_date.present?
      return I18n.t(
        :'course.courses.date.range',
        start_date: I18n.l(@course.display_start_date, format: :short_datetime),
        end_date: I18n.l(@course.end_date, format: :short_datetime)
      )
    end

    I18n.t(:'course.courses.date.coming_soon')
  end

  def enrollment
    return if @enrollments.nil?

    @enrollment ||= @enrollments.find {|enrollment| enrollment.course_id == id }
  end

  # returns true for all type of enrollments
  def enrolled?
    !enrollment.nil?
  end

  def currently_reactivated?
    enrolled? && enrollment.reactivated?
  end

  def external?
    @course.external_course_url.present?
  end

  def subtitles_info
    @subtitles_info ||= ::CourseService::Course
      .by_identifier(@course.course_code).take!
      .subtitle_offer
      .map {|lang| I18n.t(:"subtitles.languages.#{lang}") }
      .join(', ')
  end

  def teacher_names
    @course.teacher_text
  end
  alias teachers teacher_names

  def to_param
    course_code
  end

  def enrollment_id
    UUID(enrollment.try(:id)).to_param
  end

  def invite_only?
    @course.invite_only
  end

  def reactivate?
    @course.offers_reactivation? &&
      !currently_reactivated? &&
      (@course.end_date.nil? || @course.end_date < Time.zone.now) &&
      @course.was_available?
  end

  def show_certificate_requirements?
    course_wrapper.certificates_enabled?
  end

  def certificate_requirements
    course_wrapper.certificate_requirements
  end

  def public_classifiers
    if @course.classifiers.blank?
      return {}
    end

    @course.classifiers
      .where(cluster_id: visible_clusters)
      .group_by(&:cluster_id)
  end

  def category_titles
    return [] unless Xikolo.config.course_details['list_classifiers']

    classifier_ids = public_classifiers.except('level').values.flatten.pluck(:title)
    ::CourseService::Classifier.where(title: classifier_ids)
      .map(&:localized_title)
      .sort
  end

  def level
    public_classifiers['level']&.first&.localized_title
  end

  def course_wrapper
    # Temporary fix: wrapping the course in the dedicated new course presenter
    # containing shared information
    @course_wrapper ||= BasicCoursePresenter.new(@course)
  end

  private
  def externalize_description
    Xikolo::S3.externalize_file_refs(description_markup, public: true)
  end

  def visible_clusters
    @visible_clusters ||= Rails.cache.fetch(
      'web/course/clusters/visible',
      expires_in: 30.minutes,
      race_condition_ttl: 1.minute
    ) { CourseService::Cluster.visible.ids }
  end

  def date_label_with_no_end_date
    if display_start_date&.past?
      return I18n.t(:'course.courses.date.self_paced_since',
        date: I18n.l(@course.display_start_date, format: :short_datetime))
    end

    if display_start_date&.future?
      return I18n.t(:'course.courses.date.beginning',
        start_date: I18n.l(@course.display_start_date, format: :short_datetime))
    end

    I18n.t(:'course.courses.date.coming_soon')
  end

  def visual
    @visual ||= preloader.load(:visual, @course.id, [@course]) do |collection|
      Course::Visual
        .where(course_id: collection.pluck('id'))
        .group_by(&:course_id)
        .transform_values(&:first)
    end
  end
  # rubocop:disable all
end
