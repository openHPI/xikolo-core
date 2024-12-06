# frozen_string_literal: true

class VisitsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def create
    news = News.find_by(id: params[:announcement_id])

    unless news
      head :not_found, content_type: 'text/plain'
      return
    end

    news.mark_as_read(params[:user_id])

    render body: nil
  end
end
