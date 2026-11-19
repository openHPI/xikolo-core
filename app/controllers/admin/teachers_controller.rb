# frozen_string_literal: true

class Admin::TeachersController < Abstract::FrontendController
  def index
    authorize! 'course.teacher.view'

    teachers = CourseService::Teacher.with_referenced_in_courses.order(:name)
    teachers = teachers.filter_by_query(params[:q]) if params[:q].present?

    if request.xhr?
      render json: teachers.limit(10).map {|t| {id: t.id, text: t.name} }
    else
      @teachers = teachers.paginate(page: params[:page], per_page: 50)
    end
  end

  def show
    authorize! 'course.teacher.view'

    @teacher = CourseService::Teacher.find(params[:id])
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
    redirect_to action: :new, status: :see_other
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

    return render(action: :new, status: :unprocessable_content) unless @teacher.valid?

    user_id = params[:teacher][:user_id]
    teacher_resource =
      if user_id.present?
        @teacher.to_resource.merge(user_id:)
      else
        @teacher.to_resource
      end
    teacher = course_api.rel(:teachers).post(teacher_resource).value!

    add_flash_message :success, t(:'flash.success.teacher_information_created')
    redirect_to action: :show, id: teacher.fetch('id'), status: :see_other
  rescue Restify::UnprocessableEntity => e
    @teacher.remote_errors e.errors
    render action: :new, status: :unprocessable_content
  end

  def update
    authorize! 'course.teacher.manage'

    @teacher = Admin::TeacherForm.from_params params
    @teacher.persisted!

    return render(action: :edit, status: :unprocessable_content) unless @teacher.valid?

    course_api.rel(:teacher).patch(@teacher.to_resource, params: {id: params[:id]}).value!

    add_flash_message :success, t(:'flash.success.teacher_information_created')
    redirect_to action: :show, status: :see_other
  rescue Restify::UnprocessableEntity => e
    @teacher.remote_errors e.errors
    render action: :edit, status: :unprocessable_content
  end

  def destroy
    authorize! 'course.teacher.manage'

    if CourseService::Teacher.find(params[:id]).destroy
      add_flash_message :success, t(:'flash.success.teacher_deleted')
    else
      add_flash_message :error, t(:'flash.error.teacher_not_deleted')
    end

    redirect_to action: :index, status: :see_other
  end

  private

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
