# frozen_string_literal: true

class QuizSubmissionSnapshotController < Abstract::AjaxController
  before_action :ensure_logged_in

  def create
    submission = QuizService::QuizSubmission.find(snapshot_params[:quiz_submission_id])
    snapshot = submission.snapshot!(snapshot_params[:submission]&.to_unsafe_h)

    render json: {success: true, timestamp: snapshot.updated_at}
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    render json: {success: false}, status: :service_unavailable
  end

  private

  def snapshot_params
    # Allow strong parameters permit hashes with dynamic keys
    params.permit(:quiz_submission_id).tap do |whitelisted|
      whitelisted[:submission] = params[:submission]
    end
  end
end
