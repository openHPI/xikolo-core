# frozen_string_literal: true

class StepsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    respond_with Step.where index_params
  end

  def show
    respond_with Step.find params[:id]
  end

  def update
    step = Step.find params[:id]

    if step.instance_of?(Training) && !step.open
      step.open = params[:training_opened]
    end

    step.update update_params
    respond_with step.reload
  end

  def create
    respond_with Step.create create_params
  end

  private

  def index_params
    params.permit :peer_assessment_id, :type, :id, :unlock_date
  end

  def create_params
    params.permit :peer_assessment_id, :type, :position, :required_reviews
  end

  def update_params
    params.permit :unlock_date, :deadline, :optional, :required_reviews
  end
end
