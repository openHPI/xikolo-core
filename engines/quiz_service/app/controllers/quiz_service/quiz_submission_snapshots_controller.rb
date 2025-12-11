# frozen_string_literal: true

module QuizService
class QuizSubmissionSnapshotsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    snapshots = QuizSubmissionSnapshot.all
    snapshots.where! quiz_submission_id: params[:quiz_submission_id] if params[:quiz_submission_id]
    respond_with snapshots
  end

  def show
    respond_with QuizSubmissionSnapshot.find params[:id]
  end

  def create
    respond_with submission.snapshot! params[:submission]&.to_unsafe_h
  end

  def update
    respond_with QuizSubmissionSnapshot.find(params[:id]).update_attributes submission_snapshot_params
  end

  def destroy
    respond_with QuizSubmissionSnapshot.find(params[:id]).destroy
  end

  private

  def submission
    @submission ||= QuizSubmission.find params[:quiz_submission_id]
  end

  def submission_snapshot_params
    params.permit :quiz_submission_id
  end
end
end
