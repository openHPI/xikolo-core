# frozen_string_literal: true

class SectionsController < Abstract::FrontendController
  include CourseContextHelper

  before_action :ensure_content_editor, only: %i[index create destroy move update]
  before_action :load_section_nav, only: [:show]
  inside_course
  respond_to :json

  before_action(only: :create) do
    next if section_params[:alternative_state] != 'child'
    next if current_user.feature?('alternative_sections.create')

    raise AbstractController::ActionNotFound
  end

  def index
    @course_presenter = CoursePresenter.create(the_course, current_user)

    course = CourseService::Course.find(the_course.id)

    if course.legacy?
      @legacy = true
      @sections = load_raw_sections(the_course)
    else
      course.node.preload_tree!
      @sections = course.node.children
    end

    @new_section = CourseService::Section.new
  end

  # redirects to the first item in the section or to decision page for alternative sections
  def show
    section_items = CourseService::Item.where(section_id: section['id'])
    first_item = section_items.find do |item|
      item.available? && (current_user.authenticated? || item.open_mode)
    end
    # allow course preview
    if !first_item && current_user.allowed?('course.content.access')
      first_item = section_items.min_by(&:position)
      # TODO: also allow course preview for alternative sections
    end
    if first_item
      redirect_to course_item_path(id: UUID(first_item.id).to_param), status: :see_other
    elsif section['alternative_state'] == 'parent'
      @section_presenter = SectionPresenter.new(section:)
      render(layout: @section_presenter.respond_to?(:layout) ? @section_presenter.layout : 'course_area_two_cols')
    else
      # TODO: the redirect should differentiate between logged in and anonymous users
      redirect_to course_resume_path(id: UUID4(section['course_id']).to_param), status: :see_other
    end
  end

  def create
    # TODO@JG: null values
    section_params_valid_date = section_params
    if section_params_valid_date[:start_date] == ''
      section_params_valid_date = section_params_valid_date.except :start_date
    end
    if section_params_valid_date[:end_date] == ''
      section_params_valid_date = section_params_valid_date.except :end_date
    end

    @section = CourseService::Section.new section_params_valid_date # section_params
    @section.course_id = the_course.id

    if @section.save
      add_flash_message :success, t(:'flash.success.section_updated', section_title: @section.title)
      Xikolo::Pinboard::ImplicitTag.create(
        name: @section.id,
        course_id: the_course.id,
        referenced_resource: 'Xikolo::Course::Section'
      )
    else
      add_flash_message :error, t(:'flash.error.section_not_created')
    end

    redirect_to :course_sections, status: :see_other
  end

  def choose_alternative_section
    unless current_user.instrumented?
      choice = CourseService::SectionChoice.find_or_initialize_by(
        user_id: current_user.id,
        section_id: UUID(params[:id]).to_s
      )
      unless choice.choice_ids.include?(params[:chosen_id])
        choice.choice_ids << params[:chosen_id]
        choice.save!
      end
    end
    redirect_to course_section_path(id: params[:chosen_id]), status: :see_other
  end

  def update
    @section = CourseService::Section.find params[:id]
    @section.attributes = section_params

    if @section.save
      add_flash_message :success, t(:'flash.success.section_updated', section_title: @section.title)
    else
      add_flash_message :error, t(:'flash.error.section_not_updated')
    end

    redirect_to course_sections_path, status: :see_other
  end

  def destroy
    section = CourseService::Section.find params[:id]

    raise ActionController::Forbidden unless section.destroyable?

    CourseService::Section::Destroy.call(section)

    redirect_to course_sections_url, notice: t(:'flash.notice.section_deleted'), status: :see_other
  end

  def move
    section = CourseService::Section.find params[:id]

    case params[:position]
      when 'up'
        section.update({position: section.position - 1})
      when 'down'
        section.update({position: section.position + 1})
      when 'top'
        section.update({position: 1})
      when 'bottom'
        max_position = CourseService::Section.where(course_id: section.course_id).maximum(:position)
        section.update({position: max_position + 1})
      else
        section.update({position: params[:position].to_i})
    end

    head(:ok)
  end

  private

  def auth_context
    the_course.context_id
  end

  def section_params
    params.require(:xikolo_course_section).permit :title, :position, :id, :description, :start_date,
      :end_date, :optional_section, :course_id, :published, :pinboard_closed,
      :alternative_state, :parent_id, required_section_ids: []
  end

  def request_section
    course_api.rel(:section).get({id: UUID(params[:id])})
  rescue TypeError
    raise Status::NotFound
  end

  def check_course_eligibility
    super unless params[:action] == 'show'
  end

  # @deprecated Only for courses not yet migrated to the new course content tree
  def load_raw_sections(course)
    sections = course.sections
    sections.each do |section|
      section.items
      section.alternatives&.each(&:items)
    end
    sections
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
