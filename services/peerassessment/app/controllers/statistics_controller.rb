# frozen_string_literal: true

class StatisticsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def show
    respond_with Statistic.new(stat_params)
  end

  def decorate(res)
    StatisticDecorator.new res
  end

  private

  def stat_params
    params.permit :concern, :peer_assessment_id, :user_id
  end
end
