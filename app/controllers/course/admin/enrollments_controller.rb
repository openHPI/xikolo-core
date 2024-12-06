# frozen_string_literal: true

class Course::Admin::EnrollmentsController < Abstract::FrontendController
  include CourseContextHelper

  inside_course only: %i[index]
  before_action :check_course_eligibility, only: %i[create destroy]

  def index
    authorize! 'course.enrollment.index'
    if params[:page].nil?
      params[:page] = 1 # !TODO: Do this global for all paging support controllers?
    end
    # !TODO: Move this to presenter
    @enrollments = []

    @enrollments_pager = Xikolo::Course::Enrollment.where(
      course_id: the_course.id,
      page: params[:page],
      user_id: params[:user_id]
    ) do |enrollments|
      enrollments.each do |enrollment|
        item = {}
        Xikolo::Account::User.find enrollment.user_id do |user|
          item[:user] = UserPresenter.new user
          item[:data] = enrollment
          item[:features] = []
          item[:features] << t(:'admin.course_management.enrollments.proctoring') if enrollment.proctored?
          if enrollment.forced_submission_date
            item[:features] << t(:'admin.course_management.enrollments.reactivation_html',
              date: I18n.l(enrollment.forced_submission_date, format: :short)).html_safe
          end
          @enrollments << item
        end
      end
      if enrollments.empty? && params[:user_id]
        Xikolo::Account::User.find params[:user_id] do |user|
          @user = user
        end
      end
    end
    Acfs.run
  end

  def create
    authorize! 'course.enrollment.create'

    unless params[:user_id]
      add_flash_message :error, t(:'flash.error.missing_user_id_for_enrollment')
      return redirect_to action: :index
    end

    enrollments = course_api.rel(:enrollments).get(user_id: params[:user_id], course_id: the_course.id).value!
    if enrollments.empty?
      course_api.rel(:enrollments).post(user_id: params[:user_id], course_id: the_course.id).value!
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
      .get(user_id: params[:user_id], course_id: params[:course_id])
      .value!

    if enrollments.any?
      enrollments.first.rel(:self).delete.value!
      add_flash_message :notice, t(:'flash.notice.user_successfully_unenrolled')
    else
      add_flash_message :error, t(:'flash.error.unenrollment_failed')
    end

    redirect_to action: :index
  end

  def hide_course_nav?
    true
  end

  private

  def auth_context
    the_course.context_id
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
