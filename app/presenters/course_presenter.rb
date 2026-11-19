# frozen_string_literal: true

class CoursePresenter < CourseInfoPresenter
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  def_delegators :course, :id, :course_code, :classifiers, :lang, :title, :abstract, :forum_is_locked,
    :start_date, :end_date, :display_start_date, :was_available?, :available?, :published,
    :alternative_teacher_text

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
      .where(cluster_id: %w[category topic])
      .pluck(:title)
      .sort
      .uniq
  end

  def item_collection
    @item_collection ||= ::CourseService::Course.find(course.id).sections.flat_map(&:items).map do |item|
      ["#{item.section.title}: #{item.title} (#{I18n.t(:"sections.index.label.#{item.content_type}")})", item.id]
    end
  end

  def section_collection
    @section_collection ||= ::CourseService::Course.find(course.id).sections.map do |section|
      [section.title, section.id]
    end
  end

  # Does the course have an exam yet? A course can have at most one exam.
  def exam?
    @exam ||= ::CourseService::Item.joins(:section)
      .where(sections: {course_id: course.id})
      .exists?(exercise_type: 'exam')
  end

  def exam_in_this_section?(section_id)
    ::CourseService::Item.where(section_id:)
      .exists?(exercise_type: 'exam')
  end

  def exam_id
    @exam_id ||= ::CourseService::Item.joins(:section)
      .where(sections: {course_id: course.id})
      .where(exercise_type: 'exam')
      .pick(:id)
  end

  def needs_recalculation?
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
      published: published,
      categories: classifier_titles,
    }
  end

  def feed_course_url
    PublicCoursePage.url_for(self)
  end

  def recalculation_allowed?
    the_course.recalculation_allowed?
  end

  def the_course
    @the_course ||= CourseService::Course.find(course.id)
  end
end
