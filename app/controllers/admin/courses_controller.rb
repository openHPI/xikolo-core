# frozen_string_literal: true

class Admin::CoursesController < Admin::BaseController
  include CourseContextHelper

  inside_course only: [:edit]
  before_action :check_course_eligibility, only: [:destroy]

  def index
    authorize! 'course.course.index'

    courses = CourseService::Course.not_deleted.order(:title)
    courses = apply_filter(courses)
    courses = courses.autocomplete(params[:autocomplete]) if params[:autocomplete].present?

    @courses = courses.paginate(page: params[:page])
  end

  def new
    authorize! 'course.course.create'
    @course = Admin::CourseEditPresenter.for_creation user: current_user
  end

  def edit
    authorize! 'course.course.edit'
    @course_nav_active_tab = :admin

    @course = Admin::CourseEditPresenter.for_course id: params[:id], user: current_user
    Acfs.run
  end

  def create
    authorize! 'course.course.create'

    form = Admin::CourseForm.from_params params

    if form.valid?
      begin
        course = CourseService::Course::Create.call(course_resource(form.to_resource))
        if course.errors.empty?
          add_flash_message :success, t(:'flash.success.course_created')
          redirect_to course_path(id: form.course_code), status: :see_other
        else
          form.remote_errors course.errors.to_hash
          @course = Admin::CourseEditPresenter.for_creation form:, user: current_user
          render action: :new, status: :unprocessable_content
        end
      rescue ActiveRecord::RecordNotUnique
        add_flash_message :error, t(:'flash.error.course_not_created')
        @course = Admin::CourseEditPresenter.for_creation form:, user: current_user
        render action: :new, status: :unprocessable_content
      end
    else
      # Form-level validation failed
      add_flash_message :error, t(:'flash.error.course_not_created')
      @course = Admin::CourseEditPresenter.for_creation form:, user: current_user
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    authorize! 'course.course.edit'

    form = Admin::CourseForm.from_params params
    form.persisted!

    course = CourseService::Course.by_identifier(params[:id]).take
    form.id = course.id

    if form.valid? && CourseService::Course::Update.call(course,
      course_resource(form.to_resource.except('id', 'course_code')))
      add_flash_message :success, t(:'flash.success.course_updated')
      return redirect_to course_path(id: form.course_code), status: :see_other
    end

    add_flash_message :error, t(:'flash.error.course_not_updated')

    @course = Admin::CourseEditPresenter.for_course id: params[:id], form:, user: current_user
    Acfs.run

    render action: :edit, status: :unprocessable_content
  end

  def clone
    authorize! 'course.course.clone'
    if params[:new_course_code].blank?
      add_flash_message :error, t(:'sections.index.clone_course.course_code_empty')
      return redirect_to course_sections_path(params[:id]), status: :see_other
    end

    new_course = CourseService::Course.includes(:sections)
      .find_by(course_code: params[:new_course_code])

    if new_course&.sections&.any?
      add_flash_message :error, t(:'sections.index.clone_course.new_course_not_empty')
      return redirect_to course_sections_path(params[:id]), status: :see_other
    end

    CourseService::CloneCourseJob.perform_later(old_course_id: the_course.id, new_course_code: params[:new_course_code])
    add_flash_message :success, t(:'sections.index.clone_course.clone_started')
    redirect_to course_sections_path(params[:id]), status: :see_other
  end

  def destroy
    authorize! 'course.course.delete'
    course = CourseService::Course.by_identifier(params[:course_code]).take

    CourseService::Course::Destroy.call course
    redirect_to admin_courses_path, notice: t(:'flash.notice.course_deleted'), status: :see_other
  rescue Restify::ResponseError
    redirect_to course_path(params[:course_code]), error: t(:'flash.error.course_not_deleted'), status: :see_other
  end

  private

  # The form resource always includes +id+, but the create/update operations
  # manage the primary key themselves. On create a nil +id+ would clobber the
  # freshly generated one, so strip it out before handing the resource over.
  #
  # The operations look attributes up with symbol keys (e.g. the description
  # upload branch), so normalize to indifferent access just like the engine's
  # REST endpoint does with ActionController::Parameters.
  def course_resource(attributes)
    attributes.with_indifferent_access.except('id')
  end

  def apply_filter(courses)
    case params[:status]
      when 'active'      then courses.active.visible
      when 'preparation' then courses.in_preparation.visible
      when 'hidden'      then courses.where(placement: [])
      when 'upcoming'    then courses.upcoming.visible
      when 'self_paced'  then courses.self_paced.visible
      when 'archived'    then courses.where(placement: ['Archive'])
      when 'external'    then courses.where.not(external_course_url: [nil, ''])
      else courses
    end
  end

  def auth_context
    if %w[index new create clone].include? params[:action]
      :root
    else
      the_course.context_id
    end
  end

  # fix course receiving
  def request_course
    course = CourseService::Course.by_identifier(params[:id]).take
    if course.nil?
      raise Status::NotFound
    end

    course
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
