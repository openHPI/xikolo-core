# frozen_string_literal: true

class Admin::TeachersController < Abstract::FrontendController
  def index
    authorize! 'course.teacher.view'

    teachers_promise = course_api.rel(:teachers).get({
      offset: params[:offset],
      page: params.fetch(:page, 1),
      limit: 10,
      query: params[:q],
      sort: 'name',
    }.compact)

    if request.xhr?
      json = teachers_promise.value!.map do |teacher|
        {
          id: teacher['id'],
          text: teacher['name'],
        }
      end
      render json:
    else
      @teachers = Course::TeacherListPresenter.new teachers_promise
    end
  end

  def show
    authorize! 'course.teacher.view'

    @teacher = Course::TeacherListPresenter::TeacherPresenter.new(
      course_api.rel(:teacher).get({id: params[:id]}).value!
    )
  end

  def new
    authorize! 'course.teacher.manage'

    @teacher =
      if params[:user_id].present?
        Admin::TeacherForm.new(
          account_api.rel(:user).get({id: params[:user_id]}).value!
        )
      else
        Admin::TeacherForm.new
      end
  rescue Restify::NotFound
    add_flash_message :error, t(:'flash.error.associated_user_not_found')
    redirect_to action: :new
  end

  def edit
    authorize! 'course.teacher.manage'

    @teacher = Admin::TeacherForm.from_resource(
      course_api.rel(:teacher).get({id: params[:id]}).value!
    )
  end

  def create
    authorize! 'course.teacher.manage'

    @teacher = Admin::TeacherForm.from_params params

    return render(action: :new) unless @teacher.valid?

    user_id = params[:teacher][:user_id]
    teacher_resource =
      if user_id.present?
        @teacher.to_resource.merge(user_id:)
      else
        @teacher.to_resource
      end
    teacher = course_api.rel(:teachers).post(teacher_resource).value!

    add_flash_message :success, t(:'flash.success.teacher_information_created')
    redirect_to action: :show, id: teacher.fetch('id')
  rescue Restify::UnprocessableEntity => e
    @teacher.remote_errors e.errors
    render action: :new
  end

  def update
    authorize! 'course.teacher.manage'

    @teacher = Admin::TeacherForm.from_params params
    @teacher.persisted!

    return render(action: :edit) unless @teacher.valid?

    course_api.rel(:teacher).patch(@teacher.to_resource, params: {id: params[:id]}).value!

    add_flash_message :success, t(:'flash.success.teacher_information_created')
    redirect_to action: :show
  rescue Restify::UnprocessableEntity => e
    @teacher.remote_errors e.errors
    render action: :edit
  end

  private

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
