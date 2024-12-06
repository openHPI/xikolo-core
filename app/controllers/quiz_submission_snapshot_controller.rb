# frozen_string_literal: true

class QuizSubmissionSnapshotController < Abstract::AjaxController
  before_action :ensure_logged_in

  def create
    snapshot = quiz_api.rel(:quiz_submission_snapshots).post(snapshot_params.to_unsafe_h).value!

    render json: {success: true, timestamp: snapshot['updated_at']}
  rescue Restify::ResponseError
    render json: {success: false}, status: :service_unavailable
  end

  private

  def snapshot_params
    # Allow strong parameters permit hashes with dynamic keys
    params.permit(:quiz_submission_id).tap do |whitelisted|
      whitelisted[:submission] = params[:submission]
    end
  end

  def quiz_api
    @quiz_api ||= Xikolo.api(:quiz).value!
  end
end
