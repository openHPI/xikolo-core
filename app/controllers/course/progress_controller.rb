# frozen_string_literal: true

class Course::ProgressController < Abstract::FrontendController
  include Interruptible

  include CourseContextHelper

  inside_course

  before_action :set_no_cache_headers
  before_action :ensure_logged_in

  def show
    if params['user_id'].present? && current_user.allowed?('course.course.teaching')
      user = Xikolo::Account::User.find params[:user_id]
      Acfs.run
    else
      user = current_user
    end

    @course_documents = Course::DocumentsPresenter.new(
      user_id: user.id, course: the_course, current_user:
    )
    Acfs.run

    @course_progress = course_api.rel(:progresses)
      .get({user_id: user.id, course_id: the_course.id})
      .value!
      .data

    set_page_title the_course.title, t(:'courses.nav.progress')
    render(layout: !request.xhr?)
  end

  private

  def auth_context
    the_course.context_id
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
