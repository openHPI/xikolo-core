# frozen_string_literal: true

require 'xml_importer'

class QuizzesController < ApplicationController
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

    # backward compatibility
    xml_string = params[:xml].presence || params[:xml_string]

    if xml_string.present? && params[:course_id].present?
      XmlImporter::Quiz.new(params[:course_code], params[:course_id], xml_string).create_quizzes!
      head :no_content
    else
      quiz = Quiz.new id: UUID4.new
      respond_with Quiz::Store.call quiz, quiz_params
    end
  rescue XmlImporter::SchemaError,
         XmlImporter::ParameterError => e
    render json: {errors: e.errors}, status: :unprocessable_content
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

  def preview
    if params[:xml].blank? || params[:course_id].blank?
      errors = []
      errors << 'Missing "xml" parameter' if params[:xml].blank?
      errors << 'Missing "course_id" parameter' if params[:course_id].blank?
      return render json: {errors:}, status: :unprocessable_content
    end

    importer = XmlImporter::Quiz.new(params[:course_code], params[:course_id], params[:xml])

    quizzes = Array.wrap(importer.preprocess!['quizzes']['quiz']).map do |quiz|
      questions = Array.wrap(quiz.dig('questions', 'question'))
      number_answers = questions.sum do |question|
        Array.wrap(question.dig('answers', 'answer')).length
      end

      {
        name: quiz['name'],
        external_ref: quiz['external_ref'],
        section: quiz['section'],
        course_code: quiz['course_code'],
        number_questions: questions.length,
        number_answers:,
        new_record: quiz['new_record'],
      }.tap do |q|
        q['subsection'] = quiz['subsection'] if quiz.key?('subsection')
      end
    end

    render json: {
      params: params.except(:format, :controller, :action),
      quizzes:,
    }
  rescue XmlImporter::SchemaError,
         XmlImporter::ParameterError => e
    render json: {errors: e.errors}, status: :unprocessable_content
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
