# frozen_string_literal: true

module QuizService
class SubmissionQuestionStatisticsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def show
    question = Question.find(params['id'])

    respond_with question.stats.tap(&:calculate)
  end
end
end
