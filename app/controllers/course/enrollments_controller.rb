# frozen_string_literal: true

class Course::EnrollmentsController < Abstract::FrontendController
  before_action :ensure_logged_in

  rescue_from ActionController::ParameterMissing do
    raise AbstractController::ActionNotFound
  end

  def create
    enrollment = course_api
      .rel(:enrollments)
      .get({course_id: course['id'], user_id: current_user.id})
      .value!

    return redirect_to(course_resume_path(course['course_code']), status: :see_other) if enrollment.present?

    if course['invite_only'] && !current_user.allowed?('course.content.access')
      add_flash_message :error, t(:'flash.error.not_authorized')
      return redirect_to(course_path(course['course_code']), status: :see_other)
    end

    course_api.rel(:enrollments).post({user_id: current_user.id, course_id: course['id']}).value!

    add_flash_message :notice, t(:'flash.notice.enrollment_successful_short', course: course['title'])
    redirect_to course_path(course['course_code']), status: :see_other
  rescue Restify::UnprocessableEntity => e
    if e.errors['base']&.include? 'access_restricted'
      add_flash_message :error, t(:'flash.error.course_restricted')
      return redirect_to course_path(course['course_code']), status: :see_other
    end

    if e.errors['base']&.include? 'prerequisites_unfulfilled'
      add_flash_message :error, t(:'flash.error.unfulfilled_prerequisites')
      return redirect_to course_path(course['course_code']), status: :see_other
    end

    add_flash_message :notice, t(:'flash.notice.enrollment_already_present')
    redirect_to course_resume_path(course['course_code']), status: :see_other
  end

  def destroy
    raise Status::Unauthorized.new unless current_user.id == enrollment['user_id']

    enrollment.rel(:self).delete.value!

    add_flash_message :success, t(:'flash.notice.unenrollment_successful')
    redirect_to dashboard_path, status: :see_other
  end

  private

  def course
    @course ||= course_api.rel(:course).get({id: params.require(:course_id)}).value!
  rescue Restify::NotFound
    raise Status::NotFound
  end

  def enrollment
    @enrollment ||= begin
      raise Status::NotFound unless params[:id]

      course_api.rel(:enrollment).get({id: UUID(params[:id]).to_s}).value!
    end
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def auth_context
    return course['context_id'] if params[:action] == 'create'

    :root
  end

  def update_params
    params.permit(:completed).to_h
  end
end
