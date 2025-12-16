# frozen_string_literal: true

module CourseService
class ItemResultsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    results = if params[:best_per_user] == 'true'
                Result.best_per_user(item.id)
              else
                Result.where(item_id: item.id)
              end

    results = results.where(user_id: params[:user_id]) if params[:user_id]

    respond_with results
  end

  private

  def item
    Item.find(item_id)
  end

  def item_id
    params.require(:item_id)
  end
end
end
