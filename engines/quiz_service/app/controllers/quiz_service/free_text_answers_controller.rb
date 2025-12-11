# frozen_string_literal: true

module QuizService
class FreeTextAnswersController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    answers = FreeTextAnswer.all
    answers.where! question_id: params[:question_id] if params[:question_id]
    respond_with answers
  end

  def show
    respond_with FreeTextAnswer.find(params[:id])
  end

  def create
    respond_with FreeTextAnswer.create!(answer_params.merge(correct: true))
  end

  def update
    respond_with FreeTextAnswer.find(params[:id]).update!(answer_params)
  end

  def destroy
    respond_with FreeTextAnswer.find(params[:id]).destroy
  end

  private
  def answer_params
    params.permit :id, :text, :question_id, :comment, :position
  end
end
end
