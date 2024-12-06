# frozen_string_literal: true

class AnswersController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    answers = Answer.all
    answers.where! question_id: params[:question_id] if params[:question_id]
    if params[:version_at]
      answers = answers.filter_map {|answer| answer.paper_trail.version_at(DateTime.parse(params[:version_at])) }
      answers = answers.select {|answer| answer if answer.correct == !!params[:correct] } if params[:correct]
    elsif params[:correct]
      answers.where! correct: params[:correct] == 'true'
    end
    respond_with answers
  end

  def show
    answer = Answer.find(params[:id])
    answer = answer.paper_trail.version_at(DateTime.parse(params[:version_at])) if params[:version_at]
    # TODO: Error 404 if answer nil ('cause of wrong timestamp)
    answer = {} if answer.nil?
    respond_with answer
  end

  def create
    answer = Answer.new
    respond_with Answer::Store.call answer, answer_params
  end

  def update
    answer = Answer.find params[:id]
    respond_with Answer::Store.call answer, answer_params
  end

  def destroy
    respond_with Answer.find(params[:id]).destroy
  end

  def move_up
    answer = Answer.find(params[:id])
    answer.move_higher
    respond_with answer
  end

  def max_per_page
    250
  end

  def decorate(res)
    if res.is_a? Answer
      AnswerDecorator.decorate res, context: {raw: params[:raw]}
    else
      AnswerDecorator.decorate_collection res,
        context: {raw: params[:raw], collection: true}
    end
  end

  private
  def answer_params
    params.permit(
      :id,
      :question_id,
      :text,
      :comment,
      :position,
      :correct,
      :type
    )
  end
end
