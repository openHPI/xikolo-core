# frozen_string_literal: true

class QuizSubmissionQuestionsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    questions = QuizSubmissionQuestion.all
    questions.where! quiz_submission_id: params[:quiz_submission_id] if params[:quiz_submission_id]
    respond_with questions
  end

  def max_per_page
    250
  end
end
