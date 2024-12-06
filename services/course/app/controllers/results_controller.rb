# frozen_string_literal: true

class ResultsController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder
  include PointsProcessor

  respond_to :json

  def create
    result = Result.new result_params
    result.dpoints = parse_points(:points)
    result.save
    fix_errors result, :dpoints, :points
    respond_with result
  end

  def show
    respond_with Result.find params[:id]
  end

  def update
    result = Result.find params[:id]
    result.dpoints = parse_points(:points)
    result.save
    fix_errors result, :dpoints, :points
    respond_with result
  rescue ActiveRecord::RecordNotFound
    raise unless request.method == 'PUT'

    create
  end

  private

  def result_params
    params.permit(:id, :user_id, :item_id)
  end
end
