# frozen_string_literal: true

class PinboardController < Abstract::FrontendController
  include CourseContextHelper
  include PinboardRoutesHelper
  include PinboardHelper

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
    @topics = fetch_topics
    @course_code = the_course.course_code

    set_page_title the_course.title, t(:'courses.nav.discussions')
  end

  def tags
    render json: available_tags.map {|v| {id: v.name, text: v.name} }
  end

  def destroy
    tag = Xikolo::Pinboard::Tag.find params[:id]
    Acfs.run
    tag.delete
    redirect_back_or_to(root_path, status: :see_other)
  end

  def course_nav_tab
    :forum
  end

  def course_area_variant
    :light
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
    sections = CourseService::Section
      .where(course_id: the_course.id)
      .available
      .order(:position)

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

  def fetch_topics
    Thread.current[:requested_user_id] = current_user.id

    questions = PinboardService::Question.where(course_id: the_course.id, deleted: false)
    questions = questions.unblocked unless current_user.allowed?('pinboard.entity.block')
    questions = filter_by_tags(questions)

    questions = questions.default_order
    questions = questions.search(params[:q], language: the_course.lang || 'en') if params[:q].present?
    questions = order_topics(questions)

    questions
      .includes(:implicit_tags, :explicit_tags, :votes, :watches, :user_watch)
      .paginate(page: params[:page], per_page: params[:per_page] || 25)
  end

  def filter_by_tags(questions)
    if params[:section_id] == 'technical_issues'
      questions = questions.joins(:implicit_tags)
        .where(tags: {name: 'Technical Issues', course_id: the_course.id})
    elsif params[:section_id].present?
      questions = questions.joins(:implicit_tags).where(tags: {
        name: UUID(params[:section_id]).to_s,
        course_id: the_course.id,
        referenced_resource: 'Xikolo::Course::Section',
      })
    end

    tag_ids = Array(params[:tags]).flat_map {|t| t.split(',') }
    questions = questions.by_tags(tag_ids) if tag_ids.any?

    unless params[:section_id] == 'technical_issues'
      # Questions tagged with an unreferenced implicit tag (e.g. technical
      # issues) only appear on their dedicated pinboard.
      questions = questions.where.not(
        id: PinboardService::Question.joins(:implicit_tags)
          .where(tags: {referenced_resource: [nil, '']})
          .select(:id)
      )
    end

    questions
  end

  def order_topics(questions)
    case params[:order]
      when 'age'    then questions.order(created_at: :desc)
      when 'votes'  then questions.order_by_votes(:desc)
      when 'random' then questions.order(Arel.sql('RANDOM()'))
      else questions.order(updated_at: :desc)
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
      redirect_to course_pinboard_index_path(the_course.course_code), status: :see_other
    end
  end
end
