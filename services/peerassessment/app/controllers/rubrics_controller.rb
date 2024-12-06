# frozen_string_literal: true

class RubricsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    if ['true', true].include? params[:team_evaluation]
      rubrics = Rubric.unscoped.ordered.where(team_evaluation: true)
    else
      rubrics = Rubric.all
    end
    respond_with rubrics.where index_params
  end

  def show
    respond_with Rubric.unscoped.find params[:id]
  end

  def create
    assessment = PeerAssessment.find params[:peer_assessment_id]

    rubric = Rubric.new id: SecureRandom.uuid
    rubric.position = (assessment.rubrics.maximum(:position) || 0) + 1

    respond_with Rubric::Store.call(rubric, create_update_params)
  end

  def update
    rubric = Rubric.unscoped.find(params[:id])

    if params[:moveup]
      rubric.move_higher
    elsif params[:movedown]
      rubric.move_lower
    else
      rubric = Rubric::Store.call(rubric, create_update_params)
    end

    respond_with rubric
  end

  def destroy
    rubric = Rubric.unscoped.find(params[:id])
    rubric.destroy
    Xikolo::S3.extract_file_refs(rubric.hints).each do |uri|
      Xikolo::S3.object(uri).delete
    end
    respond_with rubric
  end

  def decoration_context
    {raw: params[:raw]}
  end

  private

  def index_params
    params.permit :id, :peer_assessment_id
  end

  def create_update_params
    params.permit :peer_assessment_id, :title, :hints, :position, :team_evaluation
  end
end
