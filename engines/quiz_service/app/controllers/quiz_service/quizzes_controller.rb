# frozen_string_literal: true

module QuizService
class QuizzesController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    quizzes = Quiz.all

    quizzes.where! id: params[:id] if params[:id].present?
    quizzes.where! external_ref_id: params[:external_ref_id] if params[:external_ref_id].present?
    quizzes.where! id: quiz_ids_for_course(params[:course_id]) if params[:course_id].present?

    respond_with quizzes
  end

  def show
    quiz = Quiz.find(params[:id])
    response.link clone_quiz_url(quiz), rel: :clone
    if params[:version_at].present?
      date = begin
        DateTime.parse(params[:version_at]).in_time_zone
      rescue ArgumentError
        nil
      end
      quiz = quiz.paper_trail.version_at(date) unless date.nil?
    end
    # TODO: Error 404 if quiz nil ('cause of wrong timestamp)
    respond_with quiz
  end

  def create
    return preview if params[:preview].present?

    quiz = Quiz.new id: UUID4.new
    respond_with Quiz::Store.call quiz, quiz_params
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: [e.message]}, status: :unprocessable_content
  rescue Restify::ClientError => e
    render json: {errors: [e.message]}, status: e.status
  end

  def update
    quiz = Quiz.find(params[:id])
    respond_with Quiz::Store.call quiz, quiz_params
  end

  def destroy
    respond_with Quiz.find(params[:id]).destroy
  end

  def clone
    quiz = Quiz.find params[:id]
    respond_with Quiz::Clone.call quiz
  end

  def decoration_context
    {raw: params[:raw]}
  end

  private

  def quiz_params
    params.permit(
      :id,
      :instructions,
      :time_limit_seconds,
      :allowed_attempts,
      :unlimited_time,
      :unlimited_attempts,
      :question_pool,
      :displayed_question_count,
      :pass_percentage,
      :external_ref_id
    )
  end

  def quiz_ids_for_course(course_id)
    course_api
      .rel(:items)
      .get({course_id:, content_type: 'quiz'})
      .value!
      .pluck('content_id')
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
end
