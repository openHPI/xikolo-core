# frozen_string_literal: true

class Admin::CoursesController < Admin::BaseController
  include CourseContextHelper

  before_action :set_no_cache_headers

  inside_course only: [:edit]
  before_action :check_course_eligibility, only: [:destroy]

  def index
    authorize! 'course.course.index'

    category = params[:status]
    courses = course_api.rel(:courses).get({
      alphabetic: 1,
      groups: 'any',
      **filter_params,
    }).value!

    @courses = Admin::CourseListPresenter.new(courses, category)
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

    begin
      if form.valid? && course_api.rel(:courses).post(form.to_resource).value!
        add_flash_message :success, t(:'flash.success.course_created')
        return redirect_to course_path(id: form.course_code)
      end
    rescue Restify::UnprocessableEntity => e
      form.remote_errors e.errors
    end

    # inform user:
    add_flash_message :error, t(:'flash.error.course_not_created')

    # rerender creation form
    @course = Admin::CourseEditPresenter.for_creation form:, user: current_user
    render action: :new, status: :unprocessable_entity
  end

  def update
    authorize! 'course.course.edit'

    form = Admin::CourseForm.from_params params
    form.persisted!

    course = course_api.rel(:course).get({id: params[:id]})
    form.id = course.value!['id']

    begin
      if form.valid? && course_api.rel(:course)
          .patch(
            form.to_resource.except('id', 'course_code'),
            params: {id: form.id.to_s}
          ).value!
        add_flash_message :success, t(:'flash.success.course_updated')
        return redirect_to course_path(id: form.course_code)
      end
    rescue Restify::UnprocessableEntity => e
      form.remote_errors e.errors
    end

    add_flash_message :error, t(:'flash.error.course_not_updated')

    @course = Admin::CourseEditPresenter.for_course id: params[:id], form:, user: current_user
    Acfs.run

    render action: :edit, status: :unprocessable_entity
  end

  def clone
    authorize! 'course.course.clone'
    if params[:new_course_code].blank?
      add_flash_message :error, t(:'sections.index.clone_course.course_code_empty')
      return redirect_to course_sections_path params[:id]
    end

    new_course = Xikolo::Course::Course.find_by(course_code: params[:new_course_code]) do |resource|
      resource.sections unless resource.nil? # rubocop:disable Style/SafeNavigation
    end
    Acfs.run

    if new_course.present? && new_course.sections.count > 0
      add_flash_message :error, t(:'sections.index.clone_course.new_course_not_empty')
      return redirect_to course_sections_path params[:id]
    end

    Msgr.publish({old_course_id:   the_course.id,
                  new_course_code: params[:new_course_code]}, to: 'xikolo.course.clone')
    add_flash_message :success, t(:'sections.index.clone_course.clone_started')
    redirect_to course_sections_path params[:id]
  end

  def destroy
    authorize! 'course.course.delete'
    course_api.rel(:course).get({id: params[:course_code]}).then do |course|
      course.rel(:self).delete
    end.value!
    redirect_to admin_courses_path, notice: t(:'flash.notice.course_deleted')
  rescue Restify::ResponseError
    redirect_to course_path(params[:course_code]), error: t(:'flash.error.course_not_deleted')
  end

  def hide_course_nav?
    true
  end

  private

  def filter_params
    params.permit(:page, :autocomplete, :status).to_h.symbolize_keys
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
    Xikolo::Course::Course.find(params[:id])
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
