# frozen_string_literal: true

module QuizService
class QuestionsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json
  include PointsProcessor

  def index
    questions = Question.all
    questions.where! quiz_id: params[:quiz_id] if params[:quiz_id]
    if params[:type]
      type = params[:type].start_with?('QuizService::') ? params[:type] : "QuizService::#{params[:type]}"
      questions.where!(type:)
    end
    if params[:version_at]
      questions = questions.map {|question| question.paper_trail.version_at(DateTime.parse(params[:version_at])) }
      questions = questions.select {|question| question unless question.nil? }
    end
    if params[:selftests]
      questions = selftests_for(params[:course_id])
    end
    respond_with questions
  end

  def show
    question = Question.find(params[:id])
    question = question.paper_trail.version_at(DateTime.parse(params[:version_at])) if params[:version_at]
    # TODO: Error 404 if question nil ('cause of wrong timestamp)
    question = {} if question.nil?
    respond_with question
  end

  def create
    question = Question.new
    respond_with Question::Store.call question, question_params
  end

  def update
    question = Question.find(params[:id])
    respond_with Question::Store.call question, question_params
  end

  def destroy
    question = Question.find(params[:id])
    question.remove_from_list
    destroy_status = question.destroy
    update_item_max_points question.quiz_id
    respond_with destroy_status
  end

  def decorate(res)
    if res.is_a? Question
      res.decorate context: {raw: params[:raw]}
    else # Array or ActiveRecord::Relation
      QuestionDecorator.decorate_collection(
        res,
        context: {selftests: params[:selftests] == 'true'}
      )
    end
  end

  def max_per_page
    250
  end

  private

  def selftests_for(course_id)
    selftests = []

    Xikolo.paginate(
      course_api.rel(:items).get({
        course_id:,
        content_type: 'quiz',
        exercise_type: 'selftest',
        all_available: true,
        required_items: 'none',
        per_page: 250,
      })
    ).each_page do |items|
      item_ids = items.pluck('content_id')
      Quiz.includes(questions: :answers).where(id: item_ids).find_each do |quiz|
        selftests += quiz.questions.select(&:recap?)
      end
    end

    selftests
  end

  def question_params
    permitted_params = params.permit(
      :id,
      :quiz_id,
      :text,
      :points,
      :explanation,
      :shuffle_answers,
      :type,
      :position,
      :format,
      :exclude_from_recap
    )
    if permitted_params[:type] && !permitted_params[:type].start_with?('QuizService::')
      permitted_params[:type] = "QuizService::#{permitted_params[:type]}"
    end
    permitted_params.except :format
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
end
