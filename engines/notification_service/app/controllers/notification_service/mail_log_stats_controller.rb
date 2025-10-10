# frozen_string_literal: true

module NotificationService
class MailLogStatsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  rfc6570_params show: [:news_id]

  def show
    respond_with MailLogStat.new(for_news_id: params[:news_id])
  end
end
end
