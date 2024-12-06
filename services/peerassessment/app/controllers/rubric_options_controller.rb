# frozen_string_literal: true

class RubricOptionsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    respond_with RubricOption.where index_params
  end

  def create
    respond_with RubricOption.create!(create_update_params)
  end

  def show
    respond_with RubricOption.find_by!(index_params)
  end

  def update
    respond_with RubricOption.find(params[:id]).update!(create_update_params)
  end

  def destroy
    respond_with RubricOption.find(params[:id]).destroy
  end

  private

  def index_params
    params.permit :id, :rubric_id
  end

  def create_update_params
    params.permit :rubric_id, :description, :points
  end
end
