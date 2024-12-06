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

    # The current_user is passed in to check for the presence of features (e.g. proctoring).
    # This needs to be refactored as currently the current_user is the admin/teacher
    # monitoring the progress of enrolled users in the course admin interface, not
    # the actual user. However, this doesn't matter for now since the feature
    # (proctoring) is a global platform feature.
    @course_documents = Course::DocumentsPresenter.new(user_id: user.id, course: the_course, current_user:)
    if feature?('learner_dashboard')
      @course_progress = course_api.rel(:progresses).get(user_id: user.id, course_id: the_course.id).value!
    else
      @course_progress = Course::ProgressPresenter.build user, the_course
    end
    Acfs.run

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
