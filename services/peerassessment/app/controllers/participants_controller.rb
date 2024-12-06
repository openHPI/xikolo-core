# frozen_string_literal: true

class ParticipantsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    respond_with Participant.where index_params
  end

  def show
    respond_with Participant.find_by! show_params
  end

  def create
    participant = Participant.create create_params
    respond_with participant
  end

  def update
    participant = Participant.find params[:id]
    participant.handle_update params
    respond_with participant
  end

  private

  def create_params
    params.permit :peer_assessment_id, :user_id, :group_id
  end

  def update_params
    params.permit :current_step, :expertise
  end

  def index_params
    params.permit :id, :peer_assessment_id, :current_step, :user_id
  end

  def show_params
    params.permit :id, :peer_assessment_id, :user_id
  end
end
