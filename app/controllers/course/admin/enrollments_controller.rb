# frozen_string_literal: true

class Course::Admin::EnrollmentsController < Abstract::FrontendController
  include CourseContextHelper

  inside_course only: %i[index]
  before_action :check_course_eligibility, only: %i[create destroy]

  def index
    authorize! 'course.enrollment.index'

    @enrollments = CourseService::Enrollment.active.where(course_id: the_course.id)
      .then {|enrollments| params[:user_id] ? enrollments.where(user_id: params[:user_id]) : enrollments }
      .includes(:user)
      .order(created_at: :desc, updated_at: :desc)
      .paginate(page: params[:page], per_page: 50)

    if @enrollments.empty? && params[:user_id]
      @user = AccountService::User.find(params[:user_id])
    end
  end

  def create
    authorize! 'course.enrollment.create'

    unless params[:user_id]
      add_flash_message :error, t(:'flash.error.missing_user_id_for_enrollment')
      return redirect_to action: :index, status: :see_other
    end

    enrollments = course_api.rel(:enrollments).get({user_id: params[:user_id], course_id: the_course.id}).value!
    if enrollments.empty?
      course_api.rel(:enrollments).post({user_id: params[:user_id], course_id: the_course.id}).value!
      add_flash_message :notice, t(:'flash.notice.user_successfully_enrolled')
    else
      add_flash_message :notice, t(:'flash.notice.enrollment_already_present')
    end

    redirect_to action: :index
  end

  def destroy
    authorize! 'course.enrollment.delete'

    enrollments = course_api
      .rel(:enrollments)
      .get({user_id: params[:user_id], course_id: params[:course_id]})
      .value!

    if enrollments.any?
      enrollments.first.rel(:self).delete.value!
      add_flash_message :notice, t(:'flash.notice.user_successfully_unenrolled')
    else
      add_flash_message :error, t(:'flash.error.unenrollment_failed')
    end

    redirect_to action: :index, status: :see_other
  end

  private

  def auth_context
    the_course.context_id
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
