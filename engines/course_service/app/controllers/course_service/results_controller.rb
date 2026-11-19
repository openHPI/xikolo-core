# frozen_string_literal: true

module CourseService
class ResultsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder
  include PointsProcessor

  respond_to :json

  def show
    respond_with Result.find params[:id]
  end

  def create
    result = Result.new result_params
    result.dpoints = parse_points(:points)
    result.save
    fix_errors result, :dpoints, :points
    respond_with result
  end

  def update
    result = Result.find_or_initialize_by(id: params.fetch(:id)) do
      it.assign_attributes(result_params)
    end
    result.dpoints = parse_points(:points)
    result.save
    fix_errors result, :dpoints, :points
    respond_with result
  end

  private

  def result_params
    params.permit(:id, :user_id, :item_id)
  end
end
end
