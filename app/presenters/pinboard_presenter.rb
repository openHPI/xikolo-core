# frozen_string_literal: true

class PinboardPresenter
  def initialize(course:, section: nil, technical_issues: false, filters: nil)
    @course = course
    @section = section
    @technical_issues = technical_issues
    @filters = filters
  end

  ##
  # Does this board allow posts?
  #
  def open?
    lock_reason.nil?
  end

  ##
  # If posts are not allowed, return a string that explains why.
  #
  def lock_reason
    @lock_reason ||= context.lock_reason
  end

  def breadcrumbs
    @breadcrumbs ||= context.make_breadcrumbs
  end

  def tags_filter
    @filters[:tags] if @filters.present?
  end

  def section_filter
    # Don't show the section filter if only the default section is available.
    @section_filter ||= if @filters&.dig(:sections)&.length.try(:>, 1)
                          @filters[:sections]
                        end
  end

  def current_section
    return if section_filter.blank?

    if @section.present?
      section_title = @section['title']
    elsif @technical_issues.present?
      section_title = I18n.t(:'pinboard.filters.technical_issues')
    else
      section_title = I18n.t(:'pinboard.filters.all_discussions')
    end

    section_filter.find {|s| s.first == section_title }&.last
  end

  private

  def context
    @context ||= if @technical_issues
                   TechnicalIssuesContext.new(@course)
                 elsif @section
                   SectionContext.new(@course, @section)
                 else
                   CourseContext.new(@course)
                 end
  end

  class TechnicalIssuesContext
    def initialize(course)
      @course = course
    end

    def lock_reason
      I18n.t(:'pinboard.locked_msg') if @course.forum_is_locked
    end

    def make_breadcrumbs
      PinboardBreadcrumbsPresenter.new(breadcrumbs_for_list) do |crumbs, thread|
        crumbs.with_level(
          course_section_question_path(@course.course_code, 'technical_issues', thread.id),
          thread.title
        )
      end
    end

    private

    def breadcrumbs_for_list
      Breadcrumbs.new
        .with_level(
          course_pinboard_index_path(@course.course_code),
          I18n.t('pinboard.breadcrumbs.all')
        )
        .with_level(
          course_section_pinboard_index_path(@course.course_code, 'technical_issues'),
          I18n.t('pinboard.filters.technical_issues')
        )
    end

    include Rails.application.routes.url_helpers
  end

  class SectionContext
    def initialize(course, section)
      @course = course
      @section = section
    end

    def lock_reason
      if @course.forum_is_locked
        I18n.t(:'pinboard.locked_msg')
      elsif @section['pinboard_closed']
        I18n.t(:'question.show.section_locked_msg', section: @section['title'])
      end
    end

    def make_breadcrumbs
      PinboardBreadcrumbsPresenter.new(breadcrumbs_for_list) do |crumbs, thread|
        crumbs.with_level(
          course_section_question_path(@course.course_code, section_id, thread.id),
          thread.title
        )
      end
    end

    private

    def breadcrumbs_for_list
      Breadcrumbs.new
        .with_level(
          course_pinboard_index_path(@course.course_code),
          I18n.t('pinboard.breadcrumbs.all')
        )
        .with_level(
          course_section_pinboard_index_path(@course.course_code, section_id),
          @section['title']
        )
    end

    def section_id
      UUID4(@section['id']).to_param
    end

    include Rails.application.routes.url_helpers
  end

  class CourseContext
    def initialize(course)
      @course = course
    end

    def lock_reason
      I18n.t(:'pinboard.locked_msg') if @course.forum_is_locked
    end

    def make_breadcrumbs
      PinboardBreadcrumbsPresenter.new(breadcrumbs_for_list) do |crumbs, thread|
        crumbs.with_level(
          course_question_path(@course.course_code, thread.id),
          thread.title
        )
      end
    end

    private

    def breadcrumbs_for_list
      Breadcrumbs.new
        .with_level(
          course_pinboard_index_path(@course.course_code),
          I18n.t('pinboard.breadcrumbs.all')
        )
    end

    include Rails.application.routes.url_helpers
  end
end
