# frozen_string_literal: true

class PinboardController < Abstract::FrontendController
  include CourseContextHelper
  include PinboardRoutesHelper
  include PinboardHelper

  before_action :set_no_cache_headers
  before_action :ensure_logged_in

  inside_course only: :index
  before_action :ensure_pinboard_enabled, only: :index
  before_action :load_section_nav, only: :index
  before_action :restrict_technical_issues_section, only: :index

  def index
    # This prepares some variables for the new question form
    @course = the_course

    @course_subscription = Xikolo.api(:pinboard).value!
      .rel(:course_subscriptions)
      .get({user_id: current_user.id, course_id: @course.id}).value!
      &.first

    tags = [*params[:tags]]
    if params[:section_id] == 'technical_issues'
      Xikolo::Pinboard::ImplicitTag.find_by name: 'Technical Issues', course_id: @course.id do |tag|
        tags << tag.id
        @implicit_tags = tags.join ','
      end
    elsif params[:section_id]
      SectionPresenter.new(section:).enqueue_implicit_tags do |tag|
        tags << tag.id
        @implicit_tags = tags.join ','
      end
    end

    @new_question = Xikolo::Pinboard::Question.new
    Acfs.run

    @section = section if params[:section_id] && params[:section_id] != 'technical_issues'
    @pinboard = PinboardPresenter.new(
      course: the_course,
      section: @section,
      technical_issues: params[:section_id] == 'technical_issues',
      filters:
    )
    pinboard_api.rel(:questions).get(question_params).then do |topics|
      @topics = topics
    end.value!

    @course_code = the_course.course_code

    set_page_title the_course.title, t(:'courses.nav.discussions')
    render layout: 'course_area_two_cols'
  end

  def tags
    render json: available_tags.map {|v| {id: v.name, text: v.name} }
  end

  def destroy
    tag = Xikolo::Pinboard::Tag.find params[:id]
    Acfs.run
    tag.delete
    redirect_back fallback_location: root_path
  end

  private

  def filters
    # The section filter is only available for the global pinboard.
    {
      tags: available_tags,
    }.tap { it[:sections] = available_sections }
  end

  def available_tags
    resource_params = {per_page: 150}
    resource_params[:course_id] = the_course.id
    tags = Xikolo::Pinboard::ExplicitTag.where resource_params
    Acfs.run
    tags
  end

  def available_sections
    sections = Xikolo::Course::Section.where({
      course_id: the_course.id,
      include_alternatives: true,
      published: true,
      available: true,
    })
    Acfs.run

    [
      # Always have the "All discussions" select option first.
      [
        I18n.t(:'pinboard.filters.all_discussions'),
        course_pinboard_index_path(the_course.course_code, request.query_parameters),
      ],
      # Add the "Technical Issues" section to the list of selectable sections unless disabled by config.
      unless Xikolo.config.disable_technical_issues_section
        [
          I18n.t(:'pinboard.filters.technical_issues'),
          course_section_pinboard_index_path(the_course.course_code, 'technical_issues', request.query_parameters),
        ]
      end,
      # Add the available course sections as filter options.
      *sections.map do |section|
        [
          section.title,
          course_section_pinboard_index_path(the_course.course_code, short_uuid(section.id), request.query_parameters),
        ]
      end,
    ].compact
  end

  def question_params
    {
      watch_for_user_id: current_user.id,
      course_id: the_course.id,
      question_filter_order: params[:order] || 'activity',
      blocked: current_user.allowed?('pinboard.entity.block'),
      page: params[:page] || 1,
      per_page: params[:per_page] || 25,
    }.tap do |h|
      h[:section_id] = section_id if params[:section_id].present?
      h[:search] = params[:q] if params[:q].present?
      if params[:tags].present?
        h[:tags] = params[:tags].is_a?(Array) ? params[:tags].join(',') : params[:tags]
      end
    end
  end

  def section_id
    if params[:section_id] == 'technical_issues'
      'technical'
    else
      UUID(params[:section_id]).to_s
    end
  end

  def auth_context
    the_course.context_id
  end

  ##
  # The pinboard shall not be accessible if it has been disabled for the course.
  def ensure_pinboard_enabled
    raise AbstractController::ActionNotFound unless the_course.pinboard_enabled
  end

  ##
  # Ensure that the "Technical Issues" section cannot be accessed when it is
  # disabled by config. Redirect to the general pinboard instead.
  def restrict_technical_issues_section
    return unless Xikolo.config.disable_technical_issues_section

    if params[:section_id] == 'technical_issues'
      redirect_to course_pinboard_index_path(the_course.course_code)
    end
  end

  def pinboard_api
    @pinboard_api ||= Xikolo.api(:pinboard).value!
  end
end
