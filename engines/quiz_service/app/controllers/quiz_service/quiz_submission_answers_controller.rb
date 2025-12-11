# frozen_string_literal: true

module QuizService
class QuizSubmissionAnswersController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    answers = klass.all
    if params[:quiz_submission_question_id]
      answers = answers.where(quiz_submission_question_id: params[:quiz_submission_question_id])
    end

    respond_with answers
  end

  def max_per_page
    500
  end

  private
  def klass
    QuizSubmissionAnswer
  end
end
end
