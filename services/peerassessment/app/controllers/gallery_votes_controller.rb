# frozen_string_literal: true

class GalleryVotesController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    if params[:submission_id]
      votes = GalleryVote.by_submission(params[:submission_id])
    else
      votes = GalleryVote.all
    end

    if params.key? :peer_assessment_id
      votes = votes.joins(:shared_submission)
        .where(shared_submissions: {peer_assessment_id: params[:peer_assessment_id]})
        .where(index_params)
    else
      votes = votes.where index_params
    end

    respond_with votes
  end

  def show
    if params[:submission_id]
      votes = GalleryVote.by_submission(params[:submission_id])
    else
      votes = GalleryVote.all
    end

    respond_with votes.find_by! show_params
  end

  def create
    if params[:submission_id]
      shared_submission = Submission.find(params[:submission_id]).shared_submission
    else
      shared_submission = SharedSubmission.find params[:shared_submission_id]
    end
    respond_with GalleryVote.create create_params.merge(shared_submission_id: shared_submission.id)
  end

  def update
    respond_with GalleryVote.find(params[:id]).update! update_params
  end

  def destroy
    respond_with GalleryVote.find(params[:id]).destroy
  end

  private

  def index_params
    params.permit :id, :rating, :user_id
  end

  def show_params
    params.permit :id, :rating, :user_id
  end

  def update_params
    params.permit :id, :rating, :user_id
  end

  def create_params
    params.permit :id, :rating, :user_id
  end
end
