# frozen_string_literal: true

class Course::ProgressController < Abstract::FrontendController
  include Interruptible

  include CourseContextHelper

  inside_course

  before_action :ensure_logged_in
  # The progress bar loads in a frame of a page that has already handled
  # interrupts; redirecting the frame would only break it.
  skip_before_action :check_interrupts!, only: :bar

  def show
    if params['user_id'].present? && current_user.allowed?('course.course.teaching')
      user = Xikolo::Account::User.find params[:user_id]
      Acfs.run
    else
      user = current_user
    end

    @course = the_course
    @course_progress = course_api.rel(:progresses)
      .get({user_id: user.id, course_id: the_course.id})
      .value!
      .data
    # The item the course resumes at: the last visited one, or the first one to start with
    @current_item = Item::FindCurrent.call(course: the_course, user_id: user.id)
    @quiz_list = Course::QuizListPresenter.new(the_course, user.id, @course_progress,
      current_item_id: @current_item&.id)
    @optional_items = Course::OptionalItemListPresenter.new(the_course, user.id, @course_progress,
      current_item_id: @current_item&.id)
    @completed_items_progress = Course::CompletedItemsProgress.new(the_course, user.id)

    @certificates = Course::CertificatesPresenter.new(
      course_id: the_course.id, user_id: user.id, current_user:
    )

    set_page_title the_course.title, t(:'courses.nav.progress')
    render(layout: !request.xhr?)
  end

  def bar
    @percentage = Course::CompletedItemsProgress.new(the_course, current_user.id).percentage
    render layout: false
  end

  def course_nav_tab
    :progress
  end

  def course_area_variant
    :full_width
  end

  private

  def auth_context
    the_course.context_id
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
