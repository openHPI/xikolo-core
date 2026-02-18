# frozen_string_literal: true

class Course::Admin::PermissionsController < Abstract::FrontendController
  include CourseContextHelper

  inside_course

  def index
    authorize! 'course.permissions.view'
    @permissions = Course::PermissionsPresenter.new the_course
    Acfs.run
  end

  def create
    authorize! 'course.permissions.manage'
    the_course
    Acfs.run

    Xikolo.api(:account).value!.rel(:memberships).post({group: group_name, user: params[:id]}).value!

    # Automatically enroll users in course special groups into the course
    Xikolo.api(:course).value!.rel(:enrollments).post({course_id: the_course.id, user_id: params[:id]}).value!

    redirect_to course_permissions_path(the_course.course_code), status: :see_other
  end

  def destroy
    authorize! 'course.permissions.manage'
    the_course
    Acfs.run
    Xikolo.api(:account).value!.rel(:memberships).delete({group: group_name, user: params[:id]}).value!
    redirect_to course_permissions_path(the_course.course_code), status: :see_other
  end

  def hide_course_nav?
    true
  end

  private

  def auth_context
    the_course.context_id
  end

  def group_name
    ['course', the_course.course_code, params[:group_id]].join '.'
  end
end
