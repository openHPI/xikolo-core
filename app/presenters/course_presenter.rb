# frozen_string_literal: true

class CoursePresenter < CourseInfoPresenter
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  def_delegators :course, :id, :course_code, :classifiers, :lang, :title, :abstract, :forum_is_locked,
    :start_date, :end_date, :display_start_date, :was_available?, :available?, :status, :hidden,
    :alternative_teacher_text, :fullstate

  attr_accessor :course, :enrollments

  def self.create(course, user, enrollments = nil)
    new(course:, user:, enrollments:)
  end

  def self.build_collection(*, **)
    # This presenter does not use `#build` for mapping attributes, but
    # `#create`. Therefore, we must build collections with a different
    # method than the default:
    super(*, **, &method(:create))
  end

  def classifier_titles
    course.classifiers
      .slice('category', 'topic')
      .flat_map {|_, v| v }
      .sort
      .uniq
  end

  def item_collection
    @item_collection ||= ::Course::Course.find(course.id).sections.flat_map(&:items).map do |item|
      ["#{item.section.title}: #{item.title} (#{I18n.t(:"sections.index.label.#{item.content_type}")})", item.id]
    end
  end

  def section_collection
    @section_collection ||= ::Course::Course.find(course.id).sections.map do |section|
      [section.title, section.id]
    end
  end

  alias is_enrolled enrolled?

  # Ribbon for the course recommendations
  def ribbon
    if course.fullstate == 'upcoming'
      tag.div(I18n.t(:'dashboard.starting_soon'), class: 'ribbon-horizontal-top')
    else
      tag.div(I18n.t(:'dashboard.started'), class: 'ribbon-horizontal-top ribbon-horizontal-top--highlighted')
    end
  end

  def needs_recalculation?
    return false unless recalculation_enabled?

    @user.allowed?('course.course.recalculate') &&
      the_course.needs_recalculation?
  end

  def as_feed_item
    {
      id:,
      title:,
      url: feed_course_url,
      start_date: display_start_date,
      end_date:,
      teacher: teachers,
      code: course_code,
      abstract:,
      description: description_html(external: true),
      image: visual_url,
      next_events: [],
      language: lang,
      categories: classifier_titles,
      status: course.status,
    }
  end

  def feed_course_url
    PublicCoursePage.url_for(self)
  end

  def recalculation_enabled?
    Xikolo.config.persisted_learning_evaluation.present?
  end

  def recalculation_allowed?
    the_course.recalculation_allowed?
  end

  def the_course
    @the_course ||= Course::Course.find(course.id)
  end
end
