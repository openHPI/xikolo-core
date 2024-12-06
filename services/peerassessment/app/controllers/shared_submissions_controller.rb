# frozen_string_literal: true

class SharedSubmissionsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    if params[:submission_id]
      shared_submission = SharedSubmission.joins(:submissions)
        .where(submissions: {id: params[:submission_id]})
    else
      shared_submission = SharedSubmission.where(index_params)
    end
    respond_with shared_submission.includes(:files, :submissions)
  end

  def show
    respond_with SharedSubmission.find params[:id]
  end

  private

  def index_params
    params.permit :id, :peer_assessment_id
  end
end
