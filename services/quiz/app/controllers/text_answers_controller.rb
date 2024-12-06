# frozen_string_literal: true

class TextAnswersController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    answers = TextAnswer.all
    answers.where! question_id: params[:question_id] if params[:question_id]
    respond_with answers
  end

  def show
    respond_with TextAnswer.find(params[:id])
  end

  def create
    answer = TextAnswer.new
    respond_with Answer::Store.call answer, answer_params
  end

  def update
    answer = TextAnswer.find params[:id]
    respond_with Answer::Store.call answer, answer_params
  end

  def destroy
    respond_with TextAnswer.find(params[:id]).destroy
  end

  private
  def answer_params
    params.permit :id, :question_id, :text, :comment, :position, :correct
  end
end
