# frozen_string_literal: true

class SectionsController < Abstract::FrontendController
  include CourseContextHelper
  before_action :ensure_content_editor, only: %i[index create destroy move update]
  before_action :load_section_nav, only: [:show]
  before_action :set_no_cache_headers
  inside_course
  respond_to :json

  before_action(only: :create) do
    next if section_params[:alternative_state] != 'child'
    next if current_user.feature?('alternative_sections.create')

    raise AbstractController::ActionNotFound
  end

  def index
    @course_presenter = CoursePresenter.create(the_course, current_user)

    course = Course::Course.find(the_course.id)

    if course.legacy?
      @legacy = true
      @sections = load_raw_sections(the_course)
    else
      course.node.preload_tree!
      @sections = course.node.children
    end

    Acfs.run
    @new_section = Xikolo::Course::Section.new
  end

  # redirects to the first item in the section or to decision page for alternative sections
  def show
    Acfs.add_callback the_section do |section|
      section.items do |items|
        first_item = items.find do |item|
          item.available? && (current_user.authenticated? || item.open_mode)
        end

        # allow course preview
        if !first_item && current_user.allowed?('course.content.access')
          first_item = items.min_by(&:position)
          # TODO: also allow course preview for alternative sections
        end
        if first_item
          return redirect_to course_item_path id: UUID(first_item.id).to_param
        elsif section.alternatives?
          Acfs.on section.enqueue_section_choices(current_user.id), section.alternatives do
            @section_presenter = SectionPresenter.new(section:)
            render(layout: @section_presenter.respond_to?(:layout) ? @section_presenter.layout : 'course_area_two_cols')
          end
        else
          # TODO: the redirect should differentiate between logged in and anonymous users
          return redirect_to course_resume_path id: UUID4(section.course_id).to_param
        end
      end
    end
    Acfs.run
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

    @section = Xikolo::Course::Section.new section_params_valid_date # section_params
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

    redirect_to :course_sections
  end

  def choose_alternative_section
    unless current_user.instrumented?
      Xikolo::Course::SectionChoice.create user_id: current_user.id,
        section_id: UUID(params[:id]).to_s,
        chosen_section_id: params[:chosen_id]
    end
    redirect_to course_section_path id: params[:chosen_id]
  end

  def update
    @section = Xikolo::Course::Section.find params[:id]
    Acfs.run
    @section.attributes = section_params

    if @section.save
      add_flash_message :success, t(:'flash.success.section_updated', section_title: @section.title)
    else
      add_flash_message :error, t(:'flash.error.section_not_updated')
    end

    redirect_to course_sections_path
  end

  def destroy
    section = Course::Section.find params[:id]

    raise ActionController::Forbidden unless section.destroyable?

    course_service.rel(:section).delete(id: section.id).value!

    redirect_to course_sections_url, notice: t(:'flash.notice.section_deleted')
  end

  def move
    Xikolo::Course::Section.find params[:id] do |section|
      case params[:position]
        when 'up'
          section.update_attributes({position: section.position - 1})
        when 'down'
          section.update_attributes({position: section.position + 1})
        when 'top'
          section.update_attributes({position: 1})
        when 'bottom'
          Xikolo::Course::Section.where course_id: section.course_id do |sections|
            section.update_attributes({position: sections.map(&:position).max + 1})
          end
        else
          section.update_attributes({position: params[:position].to_i})
      end
    end
    Acfs.run

    request.xhr? ? head(:ok) : redirect_to(course_sections_path)
  end

  def hide_course_nav?
    true
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
    Xikolo::Course::Section.find UUID(params[:id])
  rescue TypeError
    raise Status::NotFound
  end

  def check_course_eligibility
    super unless params[:action] == 'show'
  end

  # @deprecated Only for courses not yet migrated to the new course content tree
  def load_raw_sections(course)
    course.sections do |sections|
      sections.each do |section|
        section.items
        section.alternatives do |alternatives|
          alternatives.each(&:items)
        end
      end
    end
  end

  def course_service
    @course_service ||= Xikolo.api(:course).value!
  end
end
