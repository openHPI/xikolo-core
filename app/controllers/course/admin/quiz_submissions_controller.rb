# frozen_string_literal: true

class Course::Admin::QuizSubmissionsController < Abstract::FrontendController
  include CourseContextHelper

  before_action :set_no_cache_headers

  def add_attempt
    authorize! 'quiz.submission.grant_attempt'

    if params[:user_id] && params[:quiz_id]
      quiz_api.rel(:user_quiz_attempts).post(
        user_id: params[:user_id],
        quiz_id: params[:quiz_id]
      ).value!
    end

    add_flash_message :success, t(:'flash.success.quiz_attempt_added')
  rescue Restify::ServerError, Restify::ClientError
    add_flash_message :error, t(:'flash.error.quiz_attempt_failed')
  ensure
    redirect_back fallback_location: root_path
  end

  def add_fudge_points
    authorize! 'quiz.submission.manage'

    quiz_api.rel(:quiz_submission).patch(
      {fudge_points: params.require(:fudge_points).to_f},
      {id: params[:id]}
    ).value!

    add_flash_message :success, t(:'flash.success.fudge_points_added')
  rescue Restify::ServerError, Restify::ClientError, ActionController::ParameterMissing
    add_flash_message :error, t(:'flash.error.fudge_points_failed')
  ensure
    redirect_back fallback_location: root_path
  end

  def exclude_from_proctoring
    authorize! 'quiz.submission.manage.proctoring'

    submission = Quiz::Submission.find(UUID4(params[:id]).to_s)
    exclusion = submission.proctoring.exclude!

    if exclusion.acknowledged?
      add_flash_message :success, t(:'flash.success.proctoring.submission_excluded')
    else
      add_flash_message :error, t(:'flash.error.proctoring.submission_exclude_failed')
    end

    redirect_back fallback_location: root_path
  end

  private

  def auth_context
    the_course.context_id
  end

  def quiz_api
    @quiz_api ||= Xikolo.api(:quiz).value!
  end
end
