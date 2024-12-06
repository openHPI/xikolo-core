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
    :hidden,
    :fullstate,
    :has_collab_space,
    :pinboard_enabled,
    :rating_stars,
    :rating_votes,
    :proctored,
    :learning_goals,
    :target_groups

  def self.build(course, user, enrollments = nil)
    new(course:, user:, enrollments:)
  end

  def start_date
    return if @course['start_date'].blank?

    ::DateTime.iso8601 @course['start_date']
  end

  def end_date
    return if @course['end_date'].blank?

    ::DateTime.iso8601 @course['end_date']
  end

  def display_start_date
    return if @course['display_start_date'].blank?

    ::DateTime.iso8601 @course['display_start_date']
  end

  def effective_start_date
    display_start_date || start_date
  end

  def visual?
    visual&.image_url
  end

  def visual_url
    visual&.image_url.presence || Xikolo::V2::URL.asset_url('defaults/course.png')
  end

  def abstract_html
    render_markdown @course['abstract']
  end

  def description_markup
    @course['description']
  end

  def description_html(external: false)
    desc = render_markdown description_markup, allow_tables: true, escape_html: false
    if external && desc
      desc.gsub %r{(/files/[a-z0-9-]+)} do |match|
        Xikolo.config.base_url.join(match).to_s
      end
    else
      desc
    end
  end

  def learning_goals?
    @user.feature?('course_details.learning_goals') && learning_goals.present?
  end

  def target_groups?
    target_groups.present?
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
    @subtitles_info ||= ::Course::Course
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

  def enrollment_policy?
    enrollment_policy_url.present?
  end

  def enrollment_policy_url
    return if @course.policy_url.blank?

    @enrollment_policy_url ||= available_locales.each do |locale|
      if @course.policy_url.key?(locale)
        break @course.policy_url[locale]
      end
    end
  end

  def external_registration_url?
    invite_only? && external_registration_url.present?
  end

  def external_registration_url
    return if @course.external_registration_url.blank?

    @external_registration_url ||= Translations.new(
      @course.external_registration_url,
      locale_preference: available_locales
    ).to_s.then do |url|
      if @user.feature?('integration.external_booking')
        uri = Addressable::URI.parse(url)
        uri.query_values = (uri.query_values.presence || {}).merge('jwt' => @user.jwt)
        uri.to_s
      else
        url
      end
    end
  end

  def reactivate?
    @user.feature?('course_reactivation') &&
      CourseReactivation.enabled? &&
      @course.offers_reactivation? &&
      !currently_reactivated? &&
      (@course.end_date.nil? || @course.end_date < Time.zone.now) &&
      @course.was_available?
  end

  def show_certificate_requirements?
    @user.feature?('certificate_requirements') &&
      course_wrapper.certificates_enabled?
  end

  def certificate_requirements
    course_wrapper.certificate_requirements
  end

  def rating_widget_enabled?
    @user.feature?('course_rating') &&
      (@course.display_start_date.blank? || @course.display_start_date.past?) &&
      !invite_only?
  end

  def rating_stars_icons
    icons = []
    rounded_rating = (@course.rating_stars * 2.0).round / 2.0
    rounded_rating.to_i.times do
      icons << Global::FaIcon.new('star', style: :solid, css_classes: 'star star--filled')
    end
    if rounded_rating % 1 > 0
      icons << Global::FaIcon.new('star-half-stroke', style: :solid,
        css_classes: 'star star--filled')
    end
    icons << Global::FaIcon.new('star', css_classes: 'star') while icons.count < 5
    icons
  end

  def public_classifiers
    @course.classifiers.presence&.slice(*visible_clusters) || {}
  end

  def public_classifiers_string
    return unless Xikolo.config.course_details['list_classifiers']

    classifier_ids = public_classifiers.values.flatten.uniq
    ::Course::Classifier.where(title: classifier_ids)
      .map(&:localized_title)
      .sort
      .join(', ')
  end

  def course_wrapper
    # Temporary fix: wrapping the course in the dedicated new course presenter
    # containing shared information
    @course_wrapper ||= BasicCoursePresenter.new(@course)
  end

  private

  def visible_clusters
    @visible_clusters ||= Rails.cache.fetch(
      'web/course/clusters/visible',
      expires_in: 30.minutes,
      race_condition_ttl: 1.minute
    ) { Course::Cluster.visible.ids }
  end

  def available_locales
    [
      I18n.locale.to_s,
      Xikolo.config.locales['default'],
      *Xikolo.config.locales['available'],
    ]
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
