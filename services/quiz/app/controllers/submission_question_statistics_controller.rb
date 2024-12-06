# frozen_string_literal: true

class SubmissionQuestionStatisticsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def show
    question = Question.find(params['id'])

    respond_with question.stats.tap(&:calculate)
  end
end
