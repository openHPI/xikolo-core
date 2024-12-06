# frozen_string_literal: true

class UserStepsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  rfc6570_params index: %i[user_id]

  def index
    return render json: nil, status: :unprocessable_entity unless params[:user_id]

    respond_with Step.where(peer_assessment_id:)
  end

  def decorate(res)
    UserStepDecorator.decorate_collection res, context: {participant:}
  end

  private

  def peer_assessment_id
    params.required :peer_assessment_id
  end

  def participant
    Participant.find_by! user_id: params[:user_id]
  end
end
